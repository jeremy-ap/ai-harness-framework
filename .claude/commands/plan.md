# /plan — Create or Update Execution Plan

Create a new execution plan or update an existing one.

## Steps

1. Check `docs/exec-plans/active/` for existing plans
2. If updating an existing plan:
   - Read the plan file
   - Check off completed steps
   - Add any new steps discovered during work
   - Update the `updated` date in frontmatter
3. If creating a new plan:
   - Use the template from `docs/exec-plans/TEMPLATE.md`
   - Name the file: `NNN-short-description.md` (next sequential number)
   - Fill in the frontmatter: title, status=active, created=today, updated=today, owner
   - Break the work into numbered steps with checkboxes
   - Define clear acceptance criteria
4. Save the plan to `docs/exec-plans/active/`
5. Report the plan location and summary
