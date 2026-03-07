# Acme Billing API — Agent Configuration

## Purpose
This file configures AI coding agents for the Acme Billing API project. It is self-contained — no external file references needed.

## Project Summary
REST API for Acme Corp's billing platform. Built with TypeScript, Express, and Prisma ORM on PostgreSQL. Handles user management, billing/invoicing, and order processing.

## Commands
```bash
# Build
npm run build

# Test
npm test                                    # all tests
npm test -- --testPathPattern=<pattern>     # single test

# Lint & format
npm run lint
npm run typecheck

# Harness
./scripts/harness-doctor.sh
```

## Architecture
Layered domain architecture with three domains: `users`, `billing`, `orders`. Each domain follows the layer chain: Types -> Config -> Repo -> Service -> Runtime. Layers may only import from earlier layers (forward-only). Cross-cutting concerns (auth, telemetry, logging) enter via each domain's `providers.ts`. Cross-domain imports must go through public APIs (`index.ts`). See `architecture.json` for full specification.

## Code Conventions
- TypeScript strict mode; never use `any`
- Named exports only; no default exports
- Async/await only; no `.then()` chains
- File naming: `kebab-case.ts` for source, `*.test.ts` for tests
- Imports sorted: Node builtins, third-party, local
- All errors explicitly handled; never swallow exceptions

## Testing Requirements
- Unit tests: Jest with `ts-jest`
- Test files co-located: `src/foo.ts` -> `tests/foo.test.ts`
- Mock external services; never make real HTTP calls in tests
- No snapshot tests

## Verification Checklist
Before considering any task complete, verify ALL of the following:

- [ ] Code compiles without errors (`npm run typecheck`)
- [ ] All existing tests pass (`npm test`)
- [ ] New code has corresponding tests in `tests/`
- [ ] Tests verify behavior with meaningful assertions (not just function calls)
- [ ] No regressions in existing functionality
- [ ] Architecture boundaries respected (`./scripts/lint-architecture.sh`)
- [ ] Documentation updated if public API changed
- [ ] No leftover debug statements or TODO comments without tickets
- [ ] Commit message follows conventional commits format

## Workflow
1. Read the task or exec-plan
2. Understand the affected domains and layers
3. Make changes in small, testable increments
4. Run tests after each change
5. Verify architecture boundaries
6. Update docs if public API changes
7. Run `./scripts/harness-doctor.sh` before final commit
