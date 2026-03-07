# /lint-fix — Run Linters and Auto-Fix

Run all linters and auto-fix what can be fixed automatically.

## Steps

1. Run the project lint command with auto-fix flag (e.g., `eslint --fix`, `ruff --fix`)
2. Run `./scripts/lint-agent-config.sh` — if agent config issues found, fix them
3. Run `./scripts/lint-docs.sh` — if broken links or stale indexes found, fix them
4. Run `./scripts/lint-architecture.sh` — report violations (these need manual fixing)
5. Report what was auto-fixed and what needs manual attention
