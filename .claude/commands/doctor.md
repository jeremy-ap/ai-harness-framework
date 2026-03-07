# /doctor — Harness Health Check

Run the harness health check and report results.

## Steps

1. Run `./scripts/harness-doctor.sh` and capture the output
2. If any checks fail:
   - List each failure with the file, line, and description
   - For each failure, suggest the specific fix from the FIX field
3. If all checks pass, confirm the harness is healthy
4. If harness-doctor.sh is not found or not executable, report the issue and suggest running the install script
