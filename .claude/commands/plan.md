# /plan — Create or Update Execution Plan

Create a new execution plan or update an existing one.

## Steps

1. Read `docs/PROGRESS.md` for recent project context
2. Check `docs/exec-plans/active/` for existing plans
3. If updating an existing plan:
   - Read the plan file
   - Check off completed steps
   - Add any new steps discovered during work
   - Update the `updated` date in frontmatter
4. If creating a new plan:
   - Use the template from `docs/exec-plans/TEMPLATE.md`
   - Name the file: `NNN-short-description.md` (next sequential number)
   - Fill in the frontmatter: title, status=active, created=today, updated=today, owner
   - Break the work into numbered steps with checkboxes
   - Define clear acceptance criteria
5. Create companion verification file:
   - Copy `docs/exec-plans/VERIFY_TEMPLATE.json` to `docs/exec-plans/active/NNN-short-description.verify.json`
   - Set `plan` field to the `.md` filename (e.g., `NNN-short-description.md`)
   - Set `created` and `updated` to today's date
   - Map each acceptance criterion to at least one test
   - Always include `arch-001` for architecture compliance (unless docs-only plan)
   - All `passes` start as `false`
   - Validate JSON is well-formed: `jq . <filename>`
6. Save the plan to `docs/exec-plans/active/`
7. Report the plan location, summary, and verification test count
