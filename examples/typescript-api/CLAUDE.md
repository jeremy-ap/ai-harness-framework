# Acme Billing API

## Project Summary
REST API for Acme Corp's billing platform. Built with TypeScript, Express, and Prisma ORM on PostgreSQL. Handles user management, billing/invoicing, and order processing.

## Key Commands
- Build: `npm run build`
- Test (all): `npm test`
- Test (single): `npm test -- --testPathPattern=<pattern>`
- Lint: `npm run lint`
- Typecheck: `npm run typecheck`
- Harness check: `./scripts/harness-doctor.sh`

## Key Directories
- `src/` — Application source code, organized by domain
- `src/users/` — User management domain
- `src/billing/` — Billing and invoice domain
- `src/orders/` — Order processing domain
- `tests/` — Test files mirroring src/ structure
- `docs/` — Project documentation (@docs/DESIGN.md for architecture)
- `prisma/` — Database schema and migrations (do NOT edit migrations directly)

## Standards
- TypeScript 5.x strict mode, Node.js 20 LTS
- Follow architecture boundaries in @architecture.json
- Always run tests before committing
- No `any` types — use `unknown` and narrow

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
