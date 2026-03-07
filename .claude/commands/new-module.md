# /new-module — Scaffold a New Module

Create a new domain module following the project's layered architecture.

## Arguments
- Module name: $ARGUMENTS (the name passed after /new-module)

## Steps

1. Read `architecture.json` to understand the project's domain structure
2. Create the module directory: `src/$ARGUMENTS/`
3. Create layer files based on the project's stack:
   - `types.{{EXT}}` — Type definitions for this domain
   - `config.{{EXT}}` — Configuration for this domain
   - `repo.{{EXT}}` — Data access layer
   - `service.{{EXT}}` — Business logic
   - `runtime.{{EXT}}` — HTTP handlers / CLI commands
   - `providers.{{EXT}}` — Cross-cutting concern interfaces
   - `index.{{EXT}}` — Public API (re-exports from other layers)
4. Create test directory: `tests/$ARGUMENTS/`
5. Add the domain to `architecture.json` with:
   - path, description, layer_structure, providers, allowed_domain_dependencies, public_api, test_directory
6. Update `docs/DESIGN.md` component map if it exists
7. Report what was created
