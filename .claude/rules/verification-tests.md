# Verification Tests for Exec Plans

Always create structured verification tests alongside execution plans.

## Rules

1. When creating a new exec-plan, also create a companion `.verify.json` file using `docs/exec-plans/VERIFY_TEMPLATE.json`
2. Map each acceptance criterion to at least one test in the verification file
3. Always include an `arch-001` test for architecture compliance (unless the plan is purely docs/config)
4. All `passes` fields start as `false`
5. Never flip `passes` from `false` to `true` without executing the test steps and recording specific evidence
6. Evidence must be concrete: file paths, command output, test results — not "looks good" or "verified"
7. Do not move a plan from `active/` to `completed/` while any verification test has `passes: false`
8. Run `/verify-plan` before completing any exec-plan

## When to Skip

- Trivial changes (typo fixes, formatting)
- Documentation-only plans with no code changes
- Plans with a single obvious acceptance criterion

Even when skipping, consider whether a lightweight verification file would be useful as a completion record.

## Categories

Use these categories for test IDs:
- `func-NNN` — functional: does the feature work correctly?
- `integ-NNN` — integration: do components work together?
- `edge-NNN` — edge-case: are boundary conditions handled?
- `arch-NNN` — architecture: do changes follow project structure rules?
- `doc-NNN` — documentation: are docs updated to match changes?
