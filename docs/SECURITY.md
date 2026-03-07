# Security Model

> Replace all `{{PLACEHOLDER}}` values with project-specific content.

## Threat Model

### Threat Surfaces

{{THREAT_SURFACES}}

Enumerate all entry points where untrusted data enters the system:

| Surface | Description | Risk Level | Mitigation |
|---------|-------------|------------|------------|
| {{SURFACE_1}} | {{DESCRIPTION}} | {{RISK}} | {{MITIGATION}} |
| {{SURFACE_2}} | {{DESCRIPTION}} | {{RISK}} | {{MITIGATION}} |

### Trust Boundaries

Identify where trust levels change (e.g., public internet to internal
network, user input to database query).

## Authentication

{{AUTH_PATTERN}}

Describe the authentication mechanism:
- How users prove their identity
- Token format and lifecycle (JWT, session, API key)
- Token storage and transmission
- Session expiration and refresh strategy
- Multi-factor authentication (if applicable)

## Authorization

Describe the authorization model:
- Role-based access control (RBAC), attribute-based (ABAC), or other
- How permissions are checked and where enforcement happens
- Default deny policy: actions are forbidden unless explicitly allowed
- Permission hierarchy and inheritance

## Secrets Management

- Where secrets are stored (vault, environment variables, config files)
- How secrets are rotated
- How secrets are accessed at runtime
- What happens when a secret is compromised

**Rules:**
- Never commit secrets to version control
- Never log secrets
- Never include secrets in error messages or stack traces
- Use environment variables or a secrets manager, never hardcoded values

## Input Validation

- Validate all input at system boundaries (HTTP handlers, CLI args, file reads)
- Use allowlists over denylists
- Validate type, length, range, and format
- Sanitize output to prevent XSS
- Use parameterized queries to prevent SQL injection
- Reject unexpected fields — do not silently ignore them

## Dependency Security

- Run `npm audit` (or equivalent) in CI
- Pin dependency versions
- Review changelogs before upgrading major versions
- Monitor for CVEs in transitive dependencies
- Minimize the dependency tree — fewer deps means fewer attack surfaces

## Security Testing

- Static analysis: lint rules for common vulnerabilities
- Dependency scanning: automated CVE checks
- Penetration testing: {{PENTEST_CADENCE}}
- Security review checklist for PRs that touch auth, crypto, or input handling

## Incident Response

If a security vulnerability is discovered:

1. Assess severity and impact
2. Contain the vulnerability (disable feature, rotate secrets)
3. Fix the root cause
4. Notify affected parties per {{DISCLOSURE_POLICY}}
5. Conduct a post-mortem and update this document
