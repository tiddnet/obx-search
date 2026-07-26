.PHONY: install-hooks

install-hooks:
	@chmod +x scripts/post_push_smoke.sh
	@cp scripts/githooks/pre-push .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "Installed pre-push hook (post-deploy smoke test trampoline, ADR 0242)."
