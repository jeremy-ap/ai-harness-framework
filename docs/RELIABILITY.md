# Reliability Model

> Replace all `{{PLACEHOLDER}}` values with project-specific content.

## SLOs

{{SLO_TARGETS}}

| Metric | Target | Measurement | Window |
|--------|--------|-------------|--------|
| Availability | {{AVAILABILITY_TARGET}} | {{HOW_MEASURED}} | {{WINDOW}} |
| Latency (p50) | {{P50_TARGET}} | {{HOW_MEASURED}} | {{WINDOW}} |
| Latency (p99) | {{P99_TARGET}} | {{HOW_MEASURED}} | {{WINDOW}} |
| Error Rate | {{ERROR_RATE_TARGET}} | {{HOW_MEASURED}} | {{WINDOW}} |

Review SLOs quarterly. Tighten them as the system matures.

## Error Handling Strategy

### Principles

- Fail fast: detect errors early and surface them immediately
- Fail loud: errors must be logged and observable, never swallowed silently
- Fail safe: when in doubt, deny access / return a safe default

### Error Classification

| Category | Example | Response |
|----------|---------|----------|
| **Transient** | Network timeout, 503 | Retry with backoff |
| **Client Error** | Bad input, 400 | Return clear error, do not retry |
| **System Error** | OOM, disk full | Alert, graceful degradation |
| **Bug** | Null reference, logic error | Alert, fix immediately |

### Error Propagation

- Errors at system boundaries (HTTP, CLI) are translated to user-facing messages
- Internal errors carry context (what, where, why) for debugging
- Never expose internal details (stack traces, SQL) to external users

## Retry Policies

| Operation | Max Retries | Backoff | Timeout |
|-----------|-------------|---------|---------|
| {{OPERATION_1}} | {{RETRIES}} | {{BACKOFF}} | {{TIMEOUT}} |
| {{OPERATION_2}} | {{RETRIES}} | {{BACKOFF}} | {{TIMEOUT}} |

- Use exponential backoff with jitter
- Set a maximum retry count — unbounded retries cause cascading failures
- Make retries idempotent — the operation must be safe to repeat

## Circuit Breakers

When a downstream service fails repeatedly, stop calling it:

1. **Closed** — requests flow normally, failures are counted
2. **Open** — requests are rejected immediately, downstream gets time to recover
3. **Half-Open** — a single probe request tests if the service has recovered

| Dependency | Failure Threshold | Open Duration | Fallback |
|------------|-------------------|---------------|----------|
| {{DEPENDENCY_1}} | {{THRESHOLD}} | {{DURATION}} | {{FALLBACK}} |
| {{DEPENDENCY_2}} | {{THRESHOLD}} | {{DURATION}} | {{FALLBACK}} |

## Graceful Degradation

When a non-critical dependency is unavailable, the system should continue
operating with reduced functionality rather than failing entirely.

| Feature | Dependency | Degraded Behavior |
|---------|------------|-------------------|
| {{FEATURE_1}} | {{DEPENDENCY}} | {{DEGRADED_BEHAVIOR}} |
| {{FEATURE_2}} | {{DEPENDENCY}} | {{DEGRADED_BEHAVIOR}} |

## Monitoring and Alerting

### Key Metrics

- Request rate, error rate, latency (RED)
- Saturation: CPU, memory, disk, connections
- Business metrics: {{BUSINESS_METRICS}}

### Alerting Rules

| Alert | Condition | Severity | Runbook |
|-------|-----------|----------|---------|
| {{ALERT_1}} | {{CONDITION}} | {{SEVERITY}} | {{RUNBOOK_LINK}} |
| {{ALERT_2}} | {{CONDITION}} | {{SEVERITY}} | {{RUNBOOK_LINK}} |

- Page on symptoms (user impact), not causes
- Alerts must be actionable — if there is nothing to do, it is not an alert

## Incident Response

1. **Detect** — Automated alerts or user reports
2. **Triage** — Assess severity and impact
3. **Mitigate** — Restore service (rollback, failover, scale up)
4. **Root Cause** — Investigate after service is restored
5. **Fix** — Deploy a permanent fix
6. **Review** — Blameless post-mortem within {{POSTMORTEM_WINDOW}}

See [runbooks/](./runbooks/index.md) for specific incident procedures.
