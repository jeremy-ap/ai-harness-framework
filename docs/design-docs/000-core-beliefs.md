# Core Beliefs

- **ID**: 000
- **Status**: Draft
- **Author**: {{AUTHOR}}
- **Date**: {{DATE}}
- **Updated**: {{DATE}}

## Context

Every project rests on a set of foundational beliefs that guide decisions when
rules are ambiguous or tradeoffs are unclear. This document captures those
beliefs explicitly so that all contributors — human and agent — share the same
values.

## Beliefs

### Code Quality

- {{BELIEF_CODE_QUALITY_1}}
- {{BELIEF_CODE_QUALITY_2}}
- {{BELIEF_CODE_QUALITY_3}}

Examples: "Readability beats cleverness", "Delete code rather than comment it
out", "Simple code that works beats elegant code that might work".

### Testing

- {{BELIEF_TESTING_1}}
- {{BELIEF_TESTING_2}}
- {{BELIEF_TESTING_3}}

Examples: "Tests verify behavior, not implementation", "A test without
assertions is not a test", "Fix flaky tests immediately or delete them".

### Architecture

- {{BELIEF_ARCHITECTURE_1}}
- {{BELIEF_ARCHITECTURE_2}}
- {{BELIEF_ARCHITECTURE_3}}

Examples: "Dependencies flow in one direction", "Every module has a clear
boundary", "Cross-cutting concerns go through providers".

### Documentation

- {{BELIEF_DOCUMENTATION_1}}
- {{BELIEF_DOCUMENTATION_2}}
- {{BELIEF_DOCUMENTATION_3}}

Examples: "Docs are code — they get reviewed and tested", "A doc that is wrong
is worse than no doc", "Keep docs close to the code they describe".

### Agent Collaboration

- {{BELIEF_AGENT_COLLABORATION_1}}
- {{BELIEF_AGENT_COLLABORATION_2}}
- {{BELIEF_AGENT_COLLABORATION_3}}

Examples: "Agents follow the same rules as humans", "Agents read before they
write", "Agents verify their own work".

## Consequences

These beliefs inform all design decisions, code reviews, and architectural
choices. When a decision is ambiguous, refer back to this document.

## References

- [DESIGN.md](../DESIGN.md) — Architecture overview
- [LAYERS.md](../LAYERS.md) — Layer chain rules
- [TESTING.md](../TESTING.md) — Testing philosophy
