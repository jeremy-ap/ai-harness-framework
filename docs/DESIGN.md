# Architecture Overview

> This document describes the high-level architecture of the project.
> Replace all `{{PLACEHOLDER}}` values with project-specific content.

## System Overview

{{PROJECT_SUMMARY}}

Describe the purpose and scope of this system in 2-3 paragraphs. Include:
- What problem it solves
- Who the primary users are
- How it fits into the broader ecosystem

## Component Map

```
{{PROJECT_ROOT}}/
├── src/
│   ├── types/          # {{TYPES_DESCRIPTION}}
│   ├── config/         # {{CONFIG_DESCRIPTION}}
│   ├── repo/           # {{REPO_DESCRIPTION}}
│   ├── service/        # {{SERVICE_DESCRIPTION}}
│   ├── runtime/        # {{RUNTIME_DESCRIPTION}}
│   └── ui/             # {{UI_DESCRIPTION}}
├── scripts/            # Build, quality, and maintenance scripts
├── docs/               # Project documentation
└── tests/              # {{TEST_DESCRIPTION}}
```

Update the tree above to reflect the actual directory structure. Annotate each
directory with a brief description of its responsibility.

## Data Flow

1. **Request Ingress** — {{INGRESS_DESCRIPTION}}
2. **Validation** — {{VALIDATION_DESCRIPTION}}
3. **Business Logic** — {{BUSINESS_LOGIC_DESCRIPTION}}
4. **Data Access** — {{DATA_ACCESS_DESCRIPTION}}
5. **Response Egress** — {{EGRESS_DESCRIPTION}}

Add or remove steps as needed. Each step should name the layer (see
[LAYERS.md](./LAYERS.md)) responsible for it.

## Key Design Decisions

### Decision 1: {{DECISION_TITLE}}

| Aspect | Detail |
|--------|--------|
| **Decision** | {{DECISION}} |
| **Rationale** | {{RATIONALE}} |
| **Consequence** | {{CONSEQUENCE}} |

### Decision 2: {{DECISION_TITLE}}

| Aspect | Detail |
|--------|--------|
| **Decision** | {{DECISION}} |
| **Rationale** | {{RATIONALE}} |
| **Consequence** | {{CONSEQUENCE}} |

Add more decisions as they arise. For substantial decisions, create a full
design doc in `docs/design-docs/` instead.

## Module Dependency Rules

All module dependencies must comply with `architecture.json` at the project
root. Key rules:

- Layers follow the forward-only import rule (see [LAYERS.md](./LAYERS.md#forward-only-rule))
- Cross-domain imports must go through public APIs (see [LAYERS.md](./LAYERS.md#cross-domain-rule))
- Cross-cutting concerns use the providers pattern (see [LAYERS.md](./LAYERS.md#providers-pattern))

Run `scripts/check-architecture.sh` to verify compliance.

## External Service Contracts

| Service | Purpose | Protocol | Owner |
|---------|---------|----------|-------|
| {{EXTERNAL_SERVICE_1}} | {{PURPOSE}} | {{PROTOCOL}} | {{OWNER}} |
| {{EXTERNAL_SERVICE_2}} | {{PURPOSE}} | {{PROTOCOL}} | {{OWNER}} |

For each external dependency, document:
- The contract (API version, schema, SLA)
- Failure modes and fallback behavior
- Who to contact when it breaks

## Non-Goals

The following are explicitly out of scope for this system:

- {{NON_GOAL_1}}
- {{NON_GOAL_2}}
- {{NON_GOAL_3}}

Maintaining a clear non-goals list prevents scope creep and helps new
contributors understand boundaries.

## References

- [LAYERS.md](./LAYERS.md) — Layered architecture guide
- [TESTING.md](./TESTING.md) — Verification strategy
- [SECURITY.md](./SECURITY.md) — Security model
- [RELIABILITY.md](./RELIABILITY.md) — Reliability model
- [design-docs/](./design-docs/index.md) — Design decision records
