# Acme Worker Service — Agent Configuration

## Purpose
This file configures AI coding agents for the Acme Worker Service. Self-contained — no external file references needed.

## Project Summary
Go microservice for Acme Corp's background job processing. Exposes a REST API for job submission, persists jobs to PostgreSQL, and processes them via a worker pool. Built with Go standard library (net/http) and sqlx.

## Commands
```bash
# Build
go build ./cmd/server

# Test
go test ./...                                    # all tests
go test ./internal/<package> -run <TestName>     # single test

# Lint
golangci-lint run

# Harness
./scripts/harness-doctor.sh
```

## Architecture
Layered domain architecture with three domains: `api`, `storage`, `worker`. Each domain follows: Types -> Config -> Repo -> Service -> Runtime. Layers import forward-only. Cross-cutting concerns (auth, telemetry, logging) enter via each domain's `providers.go`. Cross-domain imports use public packages. See `architecture.json` for full specification.

## Code Conventions
- Go 1.22+, idiomatic Go patterns
- No global mutable state; pass dependencies explicitly
- Error handling: always wrap with context (`fmt.Errorf`)
- Interfaces defined by consumers, not providers
- Table-driven tests
- No `init()` functions

## Testing Requirements
- Standard `testing` package with table-driven tests
- Test files: `*_test.go` in same package
- Use `testify/assert` for assertions
- Integration tests in `tests/` directory
- Mock interfaces for external dependencies

## Verification Checklist
Before considering any task complete, verify ALL of the following:

- [ ] Code compiles (`go build ./...`)
- [ ] All existing tests pass (`go test ./...`)
- [ ] New code has corresponding `_test.go` files
- [ ] Tests verify behavior with meaningful assertions
- [ ] No regressions in existing functionality
- [ ] Architecture boundaries respected (`./scripts/lint-architecture.sh`)
- [ ] Documentation updated if public API changed
- [ ] `golangci-lint run` passes with no new warnings

## Workflow
1. Read the task or exec-plan
2. Understand the affected domains and layers
3. Make changes in small, testable increments
4. Run tests after each change
5. Verify architecture boundaries
6. Update docs if public API changes
7. Run `./scripts/harness-doctor.sh` before final commit
