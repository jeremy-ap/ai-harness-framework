# Update Docs When Public API Changes

When you modify files that are part of a module's public API, update the corresponding documentation.

## Trigger

This rule applies when you modify any file matching a `public_api` pattern in `architecture.json` (typically `src/*/index.*` files).

## Required Updates

1. If function signatures changed: update relevant docs in `docs/`
2. If new exports added: ensure they're documented
3. If exports removed: check for and update any docs referencing them
4. If behavior changed: update any relevant runbooks in `docs/runbooks/`

## How to Check

Run `./scripts/lint-docs.sh` after making changes to verify documentation is consistent.
