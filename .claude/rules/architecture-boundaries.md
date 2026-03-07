# Architecture Boundary Enforcement

Always respect the layered architecture defined in `architecture.json`.

## Layer Order (forward-only)

```
Types -> Config -> Repo -> Service -> Runtime -> UI
```

A layer may only import from layers to its LEFT (earlier in the chain).

## Four Rules

### 1. Forward-Only Layer Dependencies
- `types` — imports nothing from other layers
- `config` — may import from `types` only
- `repo` — may import from `types`, `config`
- `service` — may import from `types`, `config`, `repo`
- `runtime` — may import from `types`, `config`, `repo`, `service`
- `ui` — may import from all above

Backward imports (e.g., `service` importing from `runtime`) are forbidden.

### 2. Cross-Cutting via Providers Only
Auth, telemetry, feature flags, and logging are cross-cutting concerns. They MUST enter each domain through its `providers` file. Never import directly from cross-cutting modules.

**Wrong**: `import { verifyToken } from '../../auth/verify-token'`
**Right**: `import { auth } from './providers'`

### 3. Cross-Domain via Public API Only
When Domain A needs something from Domain B, it must import from Domain B's public API (`index.*`), never from internal files.

**Wrong**: `import { UserRepo } from '../users/repo'`
**Right**: `import { getUser } from '../users'`

### 4. Boundary Validation
External data must be parsed/validated at the boundary layer (runtime) before reaching service logic. Raw request data (`req.body`, `request.json()`, `interface{}`) must never flow directly to service functions.

**Wrong**: `userService.create(req.body)`
**Right**: `userService.create(CreateUserSchema.parse(req.body))`

## Verification

Run `./scripts/lint-architecture.sh` to check structural boundaries (layers, providers, cross-domain).
Run `./scripts/lint-boundary-validation.sh` to check data-flow boundaries (boundary validation).
