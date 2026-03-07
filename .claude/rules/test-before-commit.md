# Test Before Commit

Always run the full test suite before committing changes.

## Rules

1. Before every commit, run the project's test command
2. If tests fail, fix the failure before committing
3. Never use `--no-verify` to skip pre-commit hooks
4. If a test is flaky, fix the flakiness — do not skip or ignore it
5. New code must have corresponding tests before it can be committed
6. Tests must contain meaningful assertions — a test that calls a function without verifying its output is not a valid test

## Verification Steps

1. Run the test suite: check Key Commands in CLAUDE.md
2. Confirm all tests pass
3. If you added new code, confirm new test files exist
4. If you fixed a bug, confirm a regression test exists
