# obx-search — Claude Code context

Static frontend for search.obx.deals (GitHub Pages + Alpine.js + MapLibre).
API backend at search-api.obx.deals (Lambda container, rebuilt nightly at 06:15).
Click/watch/subscriber tracking at track.obx.deals (Lambda, `rental-intel` repo).

## Operational standards

**Observe before acting.** If a search result looks wrong, start with data —
not a code change. The most common causes in order: (1) search.db is stale
(rebuilt at 06:15; a booking that appeared after that won't be reflected until
tomorrow), (2) the Lambda image hasn't been rebuilt yet, (3) a genuine data or
logic bug. Check the timestamps before concluding it's a bug.

**Verify before fixing.** A wrong result is a symptom. Confirm the root cause
from data (when did the conflicting booking appear in inferred_bookings? what
does the raw API response show?) before changing any code.

**Separate diagnosis from action.** Identify the cause. State it clearly.
Then decide whether a code change, a DB rebuild, or just waiting for the next
06:15 cycle is the right response.

**Never push directly to main from a cron context.** The deploy_obx_deals.sh
cron writes to price-drops/ and quick-getaways/ and pushes. Do not add other
auto-generated files to that flow without an explicit ADR — stale generators
have caused page regressions (incident 2026-06-22).

## Architecture

- `index.html` — single-page app. Alpine.js state + MapLibre GL map.
  All search logic calls the Lambda API; no local DB.
- `price-drops/` — auto-generated nightly by `scripts/generate_price_drop_page.py`
  in the rental-intel repo. Do not hand-edit.
- `quick-getaways/` — auto-generated nightly by `scripts/generate_quick_getaways_page.py`.
  Do not hand-edit.

## Key ADRs

- ADR 0088 — Lambda search API architecture
- ADR 0094 — Flexible date range search + date_offset badge (Phase 5)
- ADR 0043 — Price watch alerts (watch modal, digest preference)
- ADR 0155 — Saved search alerts (save-search modal)
- ADR 0105 — Short-stay search integration

## Deployment

Changes to `index.html` go live on push to `main` (GitHub Pages, ~30s).
The search API Lambda is rebuilt at 06:15 by `deploy_obx_deals.sh` in rental-intel.
Lambda code changes (`rental-intel/terraform/lambda/click_tracker/`) require
a separate `make update-click-tracker` — they are NOT auto-deployed by the nightly cron.
