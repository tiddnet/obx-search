#!/usr/bin/env bash
# Post-push smoke-test worker (tracked; edit this file, not the
# .git/hooks/pre-push trampoline that launches it detached).
#
# Triggered by the pre-push git hook after a push that updates
# refs/heads/main. Waits for GitHub Pages to propagate, runs the live
# smoke test against search.obx.deals, and alerts via SES on failure.
# ADR 0242 (rental-intel), same detached/logged pattern as rental-intel's
# ADR 0165 post-commit hook.
#
# Always exits 0 -- nothing reads this script's exit code (it runs
# detached, disowned from the `git push` that launched it). Status is
# communicated via logs/post_push_latest.log and .json, not the exit code.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RI_ROOT="/Users/loaner/git/rental-intel"
PYTHON="$RI_ROOT/.venv/bin/python"
SITE_URL="https://search.obx.deals"
COMMIT="${1:-$(git -C "$REPO_ROOT" rev-parse --short HEAD)}"
SENTINEL="$REPO_ROOT/logs/post_push_latest.json"
PROPAGATION_WAIT=45

_write_sentinel() {
    # $1=status  $2=detail
    python3 -c "
import json
from datetime import datetime, timezone
json.dump({
    'commit': '$COMMIT',
    'status': '$1',
    'detail': '''$2''',
    'completed_at': datetime.now(timezone.utc).isoformat(timespec='seconds'),
}, open('$SENTINEL', 'w'), indent=2)
" 2>/dev/null || true
}

echo "=== post-push smoke test: $COMMIT ($SITE_URL) ==="
echo "waiting ${PROPAGATION_WAIT}s for GitHub Pages propagation..."
sleep "$PROPAGATION_WAIT"

if [ ! -x "$PYTHON" ]; then
    echo "rental-intel venv not found at $PYTHON -- cannot run smoke test."
    _write_sentinel "error" "rental-intel venv missing at $PYTHON"
    exit 0
fi

echo ""
echo "--- running scripts/test_search_site.py against $SITE_URL ---"
SMOKE_OUTPUT="$("$PYTHON" "$RI_ROOT/scripts/test_search_site.py" --url "$SITE_URL" 2>&1)"
SMOKE_EXIT=$?
echo "$SMOKE_OUTPUT"

if [ "$SMOKE_EXIT" -ne 0 ]; then
    echo ""
    echo "SMOKE TEST FAILED (exit $SMOKE_EXIT) -- sending alert."
    ALERT_SUBJECT="[post-deploy] obx-search smoke test failed after push"
    ALERT_BODY="Commit: $COMMIT
Site: $SITE_URL
Smoke test: rental-intel/scripts/test_search_site.py
Exit code: $SMOKE_EXIT

--- output ---
$SMOKE_OUTPUT
"
    (
        cd "$RI_ROOT" && \
        AWS_PROFILE="${AWS_PROFILE:-rental-intel-ses}" \
        AWS_SES_REGION="${AWS_SES_REGION:-us-east-1}" \
        AWS_SES_FROM="${AWS_SES_FROM:-Rental Intel <alerts@obx.deals>}" \
        "$PYTHON" -c "
import sys
from analysis.notify import send_health_alert
n = send_health_alert('''$ALERT_SUBJECT''', '''$ALERT_BODY''')
print(f'notify: alert sent to {n} recipient(s)', file=sys.stderr)
"
    ) 2>&1
    _write_sentinel "failed" "smoke test exit $SMOKE_EXIT"
else
    echo ""
    echo "smoke test passed."
    _write_sentinel "ok" "smoke test passed"
fi

echo "=== post-push smoke test complete ==="
exit 0
