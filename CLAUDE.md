# {{PROJECT_NAME}}

## Project Summary
{{PROJECT_SUMMARY}}

## Key Commands
- Build: `{{BUILD_COMMAND}}`
- Test (all): `{{TEST_ALL_COMMAND}}`
- Test (single): `{{TEST_SINGLE_COMMAND}}`
- Lint: `{{LINT_COMMAND}}`
- Type check: `{{TYPECHECK_COMMAND}}`
- Harness check: `./scripts/harness-doctor.sh`

## Key Directories
- `src/` — {{SRC_DESCRIPTION}}
- `tests/` — {{TESTS_DESCRIPTION}}
- `docs/` — Project documentation (@docs/DESIGN.md for architecture)
- `scripts/` — Build, lint, and harness utility scripts
- `.claude/` — Claude Code configuration and rules
- `.github/` — GitHub workflows and Copilot instructions
- `.cursor/` — Cursor IDE rules

## Standards
- {{LANGUAGE_VERSION}}
- Follow architecture boundaries in @architecture.json
- Always run tests before committing
- Keep functions small and focused
- Prefer composition over inheritance
- No `any` types (if TypeScript) / no untyped parameters (if Python)

## @-Imports (read when relevant)
@docs/DESIGN.md
@docs/LAYERS.md
@docs/TESTING.md
@docs/SECURITY.md
@.claude/rules/architecture-boundaries.md
@.claude/rules/commit-conventions.md

## Error Handling
- Handle errors at the boundary where you have context to act
- Use typed/structured errors, not raw strings
- Log errors with sufficient context for debugging
- Never swallow errors silently

## Workflow
1. Check for active exec-plan in @docs/exec-plans/active/
2. Make changes in small, testable increments
3. Run tests after each change
4. Update docs if public API changes
5. Run `./scripts/harness-doctor.sh` before final commit

## Git Conventions
- Commit messages: `type(scope): description` (conventional commits)
- Types: feat, fix, refactor, test, docs, chore, ci
- Keep commits atomic — one logical change per commit
- Never force-push to main/master

## What NOT to Do
- Do not modify generated files directly
- Do not bypass linting or type checks
- Do not add dependencies without justification
- Do not commit secrets, tokens, or credentials
