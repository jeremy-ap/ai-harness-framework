# Layered Domain Architecture

This document defines the layer chain that governs how code is organized and
how dependencies flow between modules. Every source file belongs to exactly
one layer, and imports must follow strict rules.

## The Layer Chain

```
Types -> Config -> Repo -> Service -> Runtime -> UI
  0        1        2        3          4        5
```

Each layer has a number. Higher-numbered layers depend on lower-numbered
layers, never the reverse.

| Layer | What belongs here |
|-------|-------------------|
| **Types** | Pure type definitions, interfaces, enums, constants. Zero runtime dependencies. |
| **Config** | Configuration schemas, default values, environment variable parsing. |
| **Repo** | Data access: database queries, API clients, file I/O, caches. |
| **Service** | Business logic, orchestration, domain rules. The core of the application. |
| **Runtime** | HTTP handlers, CLI commands, background jobs, WebSocket handlers. |
| **UI** | Components, views, pages, templates. Presentation layer. |

## Forward-Only Rule {#forward-only-rule}

**Each layer may only import from layers to its LEFT (lower number).**

A module in layer N can import from any layer 0..N-1, but never from N+1 or
higher. This guarantees that the dependency graph is a DAG with no cycles.

```
  ALLOWED                          FORBIDDEN
  -------                          ---------

  Types  <--  Config               Runtime  -->  Types     (OK)
  Types  <--  Service              Service  -->  Runtime   (BAD)
  Config <--  Repo                 Repo     -->  Service   (BAD)
  Repo   <--  Service              UI       -->  Repo      (BAD, skip layers
  Types  <--  Runtime              Config   -->  UI          is fine but not
                                                              backward)
```

### Example

```typescript
// service/order.ts — layer 3
import { Order } from '../types/order';     // layer 0 — OK
import { dbPool } from '../config/db';      // layer 1 — OK
import { OrderRepo } from '../repo/order';  // layer 2 — OK
import { handleOrder } from '../runtime/routes'; // layer 4 — VIOLATION
```

The last import is a forward-only violation. Service must never import from
Runtime. If Runtime needs to call Service, that is fine — the arrow points
downward. If Service needs something from Runtime, the design is wrong and
must be refactored.

## Providers Pattern {#providers-pattern}

Cross-cutting concerns — authentication, telemetry, feature flags, logging —
do not belong to any single domain layer. They MUST enter each domain through
an explicit `providers` file. Direct imports of cross-cutting modules from
business code are forbidden.

### Why

Without this rule, cross-cutting dependencies scatter across every file,
making them impossible to swap, mock, or audit.

### How

Each domain that needs a cross-cutting concern creates a `providers.ts` (or
equivalent) file that re-exports only what that domain needs.

### Correct

```typescript
// service/providers.ts
export { logger } from '../infra/logging';
export { trackEvent } from '../infra/telemetry';

// service/order.ts
import { logger, trackEvent } from './providers';
//       ^--- imports from local providers, not from infra directly
```

### Incorrect

```typescript
// service/order.ts
import { logger } from '../infra/logging';       // VIOLATION
import { trackEvent } from '../infra/telemetry';  // VIOLATION
//       ^--- direct import of cross-cutting concern
```

The `providers` file is the single point of control. To swap a logging
library, change one file per domain instead of hundreds of imports.

## Cross-Domain Rule {#cross-domain-rule}

**Domain A cannot reach into Domain B's internals.** All cross-domain
communication must go through the public API (the domain's `index.*` file).

### Correct

```typescript
// domains/billing/service/invoice.ts
import { getUser } from '../../users';  // users/index.ts — public API
```

### Incorrect

```typescript
// domains/billing/service/invoice.ts
import { getUser } from '../../users/service/user'; // VIOLATION — reaching
//                                                      into internals
```

If Domain B does not export what Domain A needs, the answer is to add it to
Domain B's public API — not to bypass the boundary.

## Boundary Validation Rule {#boundary-validation-rule}

**External data must be parsed/validated at the boundary layer before reaching
service logic.**

The `runtime` layer is where untrusted data enters the system — HTTP request
bodies, CLI arguments, queue messages, webhook payloads. If raw data flows
directly to a `service` function, the boundary is broken regardless of whether
imports are correct.

This rule enforces the invariant; the choice of validation library (Zod, Yup,
Pydantic, Bean Validation, etc.) is yours.

### Strategy: Runtime Parsing (TypeScript, Python)

For dynamically typed languages, validation happens by parsing raw data
through a schema at the boundary.

**Correct:**

```typescript
// runtime.ts — boundary layer
import { CreateUserSchema } from './types';
import { userService } from './service';

router.post('/users', (req, res) => {
  const data = CreateUserSchema.parse(req.body);  // validated
  const user = userService.create(data);           // typed data
  res.json(user);
});
```

**Incorrect:**

```typescript
// runtime.ts — boundary layer
import { userService } from './service';

router.post('/users', (req, res) => {
  const user = userService.create(req.body);  // VIOLATION — raw data
  res.json(user);
});
```

### Strategy: Static Typed (Java, Kotlin)

For statically typed languages with framework validation, the boundary is
enforced through type annotations and validation decorators.

**Correct:**

```java
@PostMapping("/users")
public User createUser(@RequestBody @Valid CreateUserDto dto) {
    return userService.create(dto);
}
```

**Incorrect:**

```java
@PostMapping("/users")
public User createUser(@RequestBody Map<String, Object> body) {
    return userService.create(body);  // VIOLATION — untyped data
}
```

### Strategy: Explicit Unmarshal (Go, Rust)

For languages without runtime type coercion, the boundary is enforced by
requiring unmarshal into typed structs.

**Correct:**

```go
func handleCreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    json.NewDecoder(r.Body).Decode(&req)  // typed struct
    user := userService.Create(req)
}
```

**Incorrect:**

```go
func handleCreateUser(w http.ResponseWriter, r *http.Request) {
    var body map[string]interface{}        // VIOLATION — untyped
    json.NewDecoder(r.Body).Decode(&body)
    user := userService.Create(body)
}
```

### Configuration

Boundary validation rules are defined in `architecture.json` under the
`boundary_validation` key. Each stack has its own strategy and set of patterns.
See the template `architecture.json` for the full schema.

### Enforcement

Run `scripts/lint-boundary-validation.sh` to verify compliance.

## Quick Reference

What each layer can import from:

| Layer | Can import from |
|-------|-----------------|
| **Types** | (nothing — leaf layer) |
| **Config** | Types |
| **Repo** | Types, Config |
| **Service** | Types, Config, Repo |
| **Runtime** | Types, Config, Repo, Service |
| **UI** | Types, Config, Repo, Service, Runtime |
| **Boundary** | Runtime files must validate external data before passing to Service |

Cross-cutting concerns (auth, logging, telemetry, feature-flags) must always
go through a `providers` file — never imported directly.

Cross-domain imports must go through the domain's `index.*` public API —
never reach into another domain's internal files.

External data entering through the runtime layer must be parsed/validated
before reaching service logic — see the Boundary Validation Rule section above.

## Enforcement

- `architecture.json` encodes these rules in machine-readable form
- `scripts/lint-architecture.sh` verifies structural compliance (layers, providers, cross-domain)
- `scripts/lint-boundary-validation.sh` verifies data-flow compliance (boundary validation)
- CI runs both checks on every pull request
