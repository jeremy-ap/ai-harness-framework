# Verification Strategy

## Philosophy

Tests exist to verify that code works correctly — not to prove that it exists.
A passing test suite should give the team confidence to ship. If it does not,
the tests are wrong.

We follow a verification-first approach: every test must answer the question
"does this behavior produce the correct result?" If a test cannot answer that
question, it should not exist.

## What to Test

**Test these:**

- Observable behavior: given input X, the output is Y
- Edge cases: empty inputs, boundary values, off-by-one scenarios
- Error paths: invalid input produces the correct error, not a crash
- Integrations: real collaborators produce correct end-to-end results

**Do NOT test these:**

- Implementation details: internal variable names, call order of private methods
- Internal state: the shape of intermediate data structures
- Framework behavior: that your ORM generates SQL, that Express calls middleware

If you refactor internals without changing behavior, zero tests should break.
If tests break on a pure refactor, those tests are coupled to implementation
and must be rewritten.

## Test Quality

A test must contain meaningful assertions. Calling a function and checking
that it "does not throw" is not a meaningful test — it verifies existence, not
correctness.

Good assertions:

```
expect(calculateTotal(items)).toBe(42.50);
expect(parseConfig('')).toEqual({ error: 'empty input' });
expect(users).toHaveLength(3);
```

Bad assertions:

```
expect(calculateTotal(items)).toBeDefined();  // proves nothing
expect(() => parseConfig('')).not.toThrow();  // does not verify result
// no assertion at all — just calling the function
```

Every test should fail if the behavior it tests is broken. If you cannot
describe a code change that would make a test fail, the test is not verifying
anything.

## Test Pyramid

```
        /  E2E  \          Few, slow, high confidence
       /----------\
      / Integration \      Some, medium speed
     /----------------\
    /      Unit        \   Many, fast, isolated
   /--------------------\
```

- **Unit tests**: Test a single function or module in isolation. Fast. Run on
  every save. These form the bulk of the suite.
- **Integration tests**: Test multiple modules working together with real
  dependencies (database, file system, HTTP). Run before commit.
- **E2E tests**: Test the full system from the user's perspective. Run in CI.
  Keep the count low — they are slow and brittle.

Aim for the pyramid shape. If most of your tests are E2E, the suite will be
slow and fragile. If you have no integration tests, you will miss wiring bugs.

## Naming

Test names describe the behavior being verified, not the function name:

```
// Good
"returns empty array when no users match the filter"
"rejects passwords shorter than 8 characters"
"retries failed requests up to 3 times"

// Bad
"test getUsers"
"test validatePassword"
"test fetchWithRetry"
```

A good test name is a sentence you could read to a non-developer and they
would understand what the system does.

## When to Write Tests

- **New features**: Write tests alongside the code. No feature is done without
  tests that verify its behavior.
- **Bug fixes**: Write a failing test that reproduces the bug first, then fix
  it. This prevents regressions.
- **Refactors**: Run the existing test suite. If tests break, the refactor
  changed behavior (or the tests were bad — fix them).
- **Before committing**: All tests must pass locally before pushing.

## Anti-Patterns

**Snapshot tests that rot.** Snapshots capture output at a point in time. They
break on every cosmetic change and get blindly updated with `--update`. If no
one reads the diff, the snapshot tests nothing.

**Mocking everything.** If a test mocks every dependency, it only tests that
mocks return what you told them to return. Use real implementations where
feasible. Reserve mocks for external services and slow I/O.

**Testing implementation details.** Asserting that a function called another
function exactly 3 times couples the test to internals. Test the result, not
the path.

**Tests without assertions.** A test that calls code without asserting the
result is a smoke test at best. It verifies the code does not crash — not that
it works. Always assert the output.

**Flaky tests.** A test that sometimes passes and sometimes fails erodes trust
in the entire suite. Fix or delete flaky tests immediately. Never mark them as
"skip" and move on.
