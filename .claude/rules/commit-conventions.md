# Commit Message Conventions

Always use conventional commits format when creating commits.

## Format
```
type(scope): description

[optional body]

[optional footer]
```

## Types
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation only
- `style` — Formatting, no code change
- `refactor` — Code change that neither fixes a bug nor adds a feature
- `test` — Adding or updating tests
- `chore` — Maintenance tasks
- `ci` — CI/CD changes

## Rules
- Subject line must be < 72 characters
- Use imperative mood: "add feature" not "added feature" or "adding feature"
- First word of description is lowercase
- No period at end of subject line
- Body explains WHY, not WHAT (the diff shows what)
- Reference issue numbers in footer: `Closes #123`

## Examples
```
feat(billing): add invoice generation endpoint

Implement POST /invoices endpoint with Stripe integration.
Includes idempotency key support for safe retries.

Closes #456
```

```
fix(auth): handle expired refresh tokens gracefully
```
