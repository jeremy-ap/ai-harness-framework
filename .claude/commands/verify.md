# /verify — Full Verification Suite

Run the complete verification suite to ensure everything is working.

## Steps

1. Run the project build command (from CLAUDE.md Key Commands)
2. Run the full test suite (from CLAUDE.md Key Commands)
3. Run the lint command (from CLAUDE.md Key Commands)
4. Run `./scripts/harness-doctor.sh` for harness-specific checks
5. Report results for each step:
   - Build: pass/fail
   - Tests: pass/fail (with failure details)
   - Lint: pass/fail (with violation count)
   - Harness: pass/fail (with check details)
6. If any step fails, investigate and fix the issue
7. Re-run failed checks after fixes to confirm resolution
