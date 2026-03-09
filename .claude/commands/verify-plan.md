# /verify-plan — Verify Exec-Plan Acceptance Criteria

Run structured verification tests for an active execution plan.

## Steps

1. List all `.md` files in `docs/exec-plans/active/`
   - If no active plans exist, report "No active plans found" and stop
   - If multiple active plans exist, ask the user which plan to verify
2. For the selected plan, look for a companion `.verify.json` file (same name but `.verify.json` instead of `.md`)
   - If missing, offer to create one:
     - Read the plan's `## Acceptance Criteria` section
     - Use `docs/exec-plans/VERIFY_TEMPLATE.json` as the base
     - Map each acceptance criterion to at least one test
     - Always include `arch-001` (architecture compliance) unless the plan is docs-only
     - Set `plan` field to the `.md` filename
     - Set `created` and `updated` to today's date
     - All `passes` start as `false`
     - Validate the JSON is well-formed with `jq .`
3. Load and display the current verification state:
   - Total tests, passing count, failing count
   - List each failing test with its ID and description
4. For each failing test:
   - Display the test steps
   - Execute each step (run commands, check files, inspect output)
   - Record specific evidence of the result:
     - Test file paths and pass/fail output
     - Command output (trimmed to relevant lines)
     - Concrete observations ("function X returns Y when given Z")
   - **"Looks good" is NOT acceptable evidence** — be specific
   - If the test passes: set `"passes": true` and fill in `"evidence"` with what you observed
   - If the test fails: leave `"passes": false` and note what still needs work in the plan's Notes section
5. Update the `updated` date in the JSON and save the file
6. Report final state:
   - All passing → "All verification tests pass. Plan is ready to complete."
   - Any failing → "N of M tests still failing. Continue working on the plan."

## Guidelines

- Evidence must be specific and verifiable: file paths, command output, concrete observations
- Do not flip `passes` to `true` without actually executing the test steps
- If a test step involves running a command, run it and include relevant output
- If a test is no longer relevant (requirements changed), update the test rather than removing it
- After verification, the `.verify.json` serves as a structured record of what was checked and how
