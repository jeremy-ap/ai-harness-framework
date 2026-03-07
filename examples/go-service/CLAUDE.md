# Acme Worker Service

## Project Summary
Go microservice for Acme Corp's background job processing. Exposes a REST API for job submission, persists jobs to PostgreSQL, and processes them via a worker pool. Built with Go standard library (net/http) and sqlx.

## Key Commands
- Build: `go build ./cmd/server`
- Test (all): `go test ./...`
- Test (single): `go test ./internal/<package> -run <TestName>`
- Lint: `golangci-lint run`
- Harness check: `./scripts/harness-doctor.sh`

## Key Directories
- `cmd/` — Application entry points (server, worker CLI)
- `internal/` — Private application code, organized by domain
- `internal/api/` — HTTP API domain
- `internal/storage/` — Data persistence domain
- `internal/worker/` — Background job processing domain
- `tests/` — Integration tests
- `docs/` — Project documentation (@docs/DESIGN.md for architecture)

## Standards
- Go 1.22+, golangci-lint, no global state
- Follow architecture boundaries in @architecture.json
- Always run tests before committing
- Error wrapping with `fmt.Errorf("context: %w", err)`

## @-Imports (read when relevant)
@docs/DESIGN.md
@docs/LAYERS.md
@docs/TESTING.md
@docs/SECURITY.md
@.claude/rules/architecture-boundaries.md
@.claude/rules/commit-conventions.md

## Workflow
1. Check for active exec-plan in @docs/exec-plans/active/
2. Make changes in small, testable increments
3. Run tests after each change
4. Update docs if public API changes
5. Run `./scripts/harness-doctor.sh` before final commit
