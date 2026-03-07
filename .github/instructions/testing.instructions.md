---
applyTo: "**/tests/**,**/*.test.*,**/*.spec.*,**/test_*"
---

# Testing Conventions

## File Naming
- Test files must match the pattern: `{{TEST_FILE_PATTERN}}`
- Place test files adjacent to the source file or in the `tests/` directory, following existing project conventions
- Mirror the source directory structure in `tests/`

## Test Structure
- Use descriptive test names that explain the expected behavior
- Good: `should return 404 when user is not found`
- Bad: `test user`, `works correctly`
- Group related tests using describe/context blocks where the framework supports it
- Follow the Arrange-Act-Assert pattern within each test

## Assertions
- Every test MUST contain meaningful assertions that verify behavior
- Do not write tests that only check if code runs without throwing
- Assert on return values, state changes, side effects, or error conditions
- Use specific assertions (e.g., `toEqual`, `assert_called_with`) over generic ones (e.g., `toBeTruthy`)
- When testing error cases, assert on the error type and message

## Mocking
- Mock external dependencies (network calls, databases, file system, third-party APIs)
- Do not mock the unit under test
- Keep mocks minimal — only mock what is necessary for isolation
- Verify mock interactions when the side effect is the primary behavior being tested

## Coverage
- New features and bug fixes must include corresponding tests
- Cover the happy path, edge cases, and error conditions
- Do not write tests solely to increase coverage numbers — each test should verify a meaningful behavior

## Running Tests
- Single test: `{{TEST_SINGLE_COMMAND}}`
- All tests: `{{TEST_ALL_COMMAND}}`
- Always run the full suite before committing
