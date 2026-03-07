# /review — Self-Review Before Commit

Review all pending changes before committing.

## Steps

1. Run `git diff --staged` (or `git diff` if nothing staged) to see all changes
2. For each changed file, check:
   - [ ] No leftover debug statements (console.log, print, debugger, TODO without ticket)
   - [ ] No commented-out code blocks
   - [ ] No hardcoded secrets or credentials
   - [ ] Error handling is present where needed
   - [ ] Function/variable names are clear and consistent
3. Run `./scripts/lint-architecture.sh` to verify architecture boundaries
4. Run `./scripts/verify-tests-exist.sh` to verify test coverage
5. Check if any changed files are public APIs — if so, verify docs are updated
6. Verify commit message follows conventional commits format
7. Report review findings:
   - Issues that must be fixed before commit
   - Warnings to consider
   - Confirmation if everything looks good
