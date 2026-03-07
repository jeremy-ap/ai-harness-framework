# {{PROJECT_NAME}} — GitHub Copilot Instructions

## Project Overview
{{PROJECT_NAME}} is {{PROJECT_SUMMARY}}.

## Language and Runtime
{{LANGUAGE_VERSION}}

## Architecture
This project uses a layered architecture with strict dependency rules. Dependencies flow inward only:

- Presentation/API Layer: Handles requests and user interaction. Depends on Service layer only.
- Service/Business Logic Layer: Core business rules. Depends on Data layer only.
- Data/Repository Layer: Persistence and external data access. Depends on Shared only.
- Shared/Core: Types, utilities, constants. No dependencies on other layers.

Never skip layers. Never create circular dependencies. Refer to `architecture.json` in the project root for machine-readable boundary definitions.

## Coding Standards
- Use meaningful, descriptive names for functions and variables.
- Keep functions small and focused on a single responsibility.
- Prefer composition over inheritance.
- Handle errors at the boundary where you have context to act on them.
- Use typed/structured errors rather than raw strings.
- No `any` types (TypeScript) or untyped parameters (Python).
- Do not modify generated files directly.
- Do not add dependencies without clear justification.

## File Organization
- `src/` contains source code organized by architectural layer.
- `tests/` contains test files mirroring the source structure.
- `docs/` contains project documentation. `docs/DESIGN.md` has the full architecture.
- `scripts/` contains build, lint, and utility scripts.

## Testing Conventions
- Every new feature or bug fix must include corresponding tests.
- Test files follow the pattern: `{{TEST_FILE_PATTERN}}`.
- Tests must contain meaningful assertions that verify actual behavior.
- Use descriptive test names that explain expected behavior (e.g., `should return 404 when user not found`).
- Mock external dependencies; never make real network calls in unit tests.
- Run `{{TEST_ALL_COMMAND}}` to execute the full suite.

## Commit Messages
Follow conventional commits: `type(scope): description`

Types: feat, fix, refactor, test, docs, chore, ci.

## What to Avoid
- Do not generate code that bypasses architecture boundaries.
- Do not introduce `console.log` or `print` statements for debugging in committed code.
- Do not suggest force-pushing or destructive git operations.
- Do not commit secrets, tokens, API keys, or credentials.
- Do not add broad catch-all error handlers that swallow errors silently.
