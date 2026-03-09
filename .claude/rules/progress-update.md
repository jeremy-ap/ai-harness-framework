# Keep Progress Log Updated

Update `docs/PROGRESS.md` when significant work is completed.

## When to Update

- After completing an exec-plan
- After implementing a significant feature or fix
- After making architectural changes or key decisions
- At the end of a substantial work session

## When NOT to Update

- Trivial fixes (typos, formatting, single-line changes)
- Documentation-only changes
- Dependency bumps with no behavior change
- Work-in-progress that isn't yet meaningful to summarize

## How to Update

Run `/progress` for a guided update, or manually:
1. Add a new `### YYYY-MM-DD` entry at the top of the Log section
2. Include 2-5 bullet points of concrete outcomes
3. Update the Current Status section at the top

## Enforcement

- `scripts/lint-progress.sh` warns at 3+ commits since last entry, fails at 10+
- `harness-doctor` includes progress staleness in health checks
- Pre-push hook blocks pushing when progress is significantly stale
