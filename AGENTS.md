# {{PROJECT_NAME}} — Agent Instructions

## Purpose
This file provides self-contained instructions for any AI coding agent working on this project. It is designed to be tool-agnostic and does not use @-imports or tool-specific features.

## Project Summary
{{PROJECT_SUMMARY}}

## Key Commands
- Build: `{{BUILD_COMMAND}}`
- Test (all): `{{TEST_ALL_COMMAND}}`
- Test (single): `{{TEST_SINGLE_COMMAND}}`
- Lint: `{{LINT_COMMAND}}`
- Type check: `{{TYPECHECK_COMMAND}}`
- Architecture lint: `./scripts/lint-architecture.sh`
- Boundary validation: `./scripts/lint-boundary-validation.sh`
- Harness check: `./scripts/harness-doctor.sh`

## Project Structure
```
src/            — {{SRC_DESCRIPTION}}
tests/          — {{TESTS_DESCRIPTION}}
docs/           — Project documentation (DESIGN.md has full architecture)
scripts/        — Build, lint, and utility scripts
architecture.json — Machine-readable architecture boundaries
```

## Architecture
This project follows a layered architecture. The layers, from outermost to innermost:

1. **Presentation / API Layer** — Handles HTTP requests, CLI commands, or UI rendering. Depends on the Service layer. Never accesses the Data layer directly.
2. **Service / Business Logic Layer** — Contains core business rules and orchestration. Depends on the Data layer. Does not depend on Presentation.
3. **Data / Repository Layer** — Manages persistence, external API calls, and data access. Does not depend on Service or Presentation.
4. **Shared / Core** — Utilities, types, and constants used across all layers. Has no dependencies on other layers.

Dependencies flow inward only: Presentation -> Service -> Data -> Shared. Never skip layers. Never create circular dependencies. External data entering the Presentation/API layer must be parsed/validated before reaching the Service layer — raw request data must never flow directly to service functions. The file `architecture.json` in the project root defines these boundaries in machine-readable form.

## Code Conventions
- {{LANGUAGE_VERSION}}
- Use meaningful, descriptive names for functions and variables
- Keep functions small and focused on a single responsibility
- Prefer composition over inheritance
- Handle errors at boundaries where you have context to act
- Use typed/structured errors, not raw strings
- No `any` types (TypeScript) / no untyped parameters (Python)
- Do not modify generated files directly
- Do not add dependencies without justification

## Testing Requirements
- Every new feature or bug fix must include corresponding tests
- Test file naming: `{{TEST_FILE_PATTERN}}`
- Place tests adjacent to source or in the `tests/` directory, following existing conventions
- Tests must contain meaningful assertions that verify behavior, not just existence
- Use descriptive test names that explain the expected behavior
- Aim for tests that are independent and can run in any order
- Mock external dependencies; do not make real network calls in unit tests
- Run the full test suite before considering work complete

## Verification Checklist
Before considering any task complete, verify ALL of the following:

- [ ] Code compiles/builds without errors (`{{BUILD_COMMAND}}`)
- [ ] All existing tests pass (`{{TEST_ALL_COMMAND}}`)
- [ ] New code has corresponding tests
- [ ] Tests verify behavior, not just existence (contain meaningful assertions)
- [ ] No regressions in existing functionality
- [ ] Architecture boundaries respected (`./scripts/lint-architecture.sh`)
- [ ] Boundary validation respected (`./scripts/lint-boundary-validation.sh`)
- [ ] Lint passes with no new warnings (`{{LINT_COMMAND}}`)
- [ ] Documentation updated if public API changed
- [ ] No secrets, tokens, or credentials in committed code
- [ ] Commit messages follow conventional commit format

This checklist is mandatory. Skipping verification leads to broken builds, silent regressions, and wasted review cycles. Run each check and confirm it passes.

## Git Conventions
- Commit messages: `type(scope): description`
- Types: feat, fix, refactor, test, docs, chore, ci
- Keep commits atomic — one logical change per commit
- Never force-push to main/master

## Workflow
0. Read `docs/PROGRESS.md` for recent project history and current state
1. Read `docs/exec-plans/active/` for any active execution plan
2. Understand the relevant code before making changes
3. Make changes in small, testable increments
4. Run tests after each change
5. Run the full verification checklist before final commit
6. Update documentation if public API changes
7. Run `./scripts/harness-doctor.sh` as a final sanity check
8. For significant work, update the progress log (`/progress` in Claude Code, or manually edit `docs/PROGRESS.md`)
