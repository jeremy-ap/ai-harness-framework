# Harness Framework

A pluggable harness framework — drop these files into any greenfield repo to make it immediately agent-optimized.

Inspired by OpenAI's [Harness Engineering](https://openai.com/index/harness-engineering/) approach: the bottleneck is never the agent's ability to write code, but the lack of structure, tools, and feedback mechanisms surrounding it.

## Quick Start

```bash
# Install harness into your project
./install.sh /path/to/your-repo

# Follow the customization checklist printed by the installer
# Then verify everything works:
cd /path/to/your-repo
./scripts/harness-doctor.sh
```

## What's Included

| Category | Files | Purpose |
|----------|-------|---------|
| Agent Config | `CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`, `copilot-instructions.md` | Configure AI coding tools |
| Architecture | `architecture.json`, `docs/LAYERS.md` | Declarative module boundaries & layered architecture |
| Documentation | `docs/` | Design docs, exec plans, product specs, runbooks, tech debt tracking |
| Enforcement | `scripts/*.sh` | Linters for architecture, docs, agent config, tests, commits |
| CI/CD | `.github/workflows/` | Automated checks on every PR |
| Git Hooks | `.githooks/` | Pre-commit, commit-msg, pre-push validation |
| Commands | `.claude/commands/` | Claude Code slash commands (`/doctor`, `/plan`, `/verify`, etc.) |

## Key Principles

1. **Repository as system of record** — All knowledge lives in the repo, not in Slack, Docs, or heads.
2. **Agent legibility over human preferences** — Optimize for what agents understand.
3. **Enforce invariants, not implementations** — Strict boundaries, flexible filling.
4. **Progressive disclosure** — Short entry-point files linking to deeper docs via @-imports.
5. **Mechanical enforcement** — Linters with remediation-aware error messages.
6. **Boring technology** — Composable, well-documented, stable tools.
7. **Verification over structure** — Tests must verify behavior, not just existence.

## Architecture Enforcement

The framework enforces a **layered domain architecture**:

```
Types → Config → Repo → Service → Runtime → UI
```

Four rules are mechanically checked by `lint-architecture.sh` and `lint-boundary-validation.sh`:

1. **Forward-only layers** — A layer may only import from layers to its left (earlier in the chain).
2. **Cross-cutting via Providers** — Auth, telemetry, feature flags, and logging enter each domain through an explicit `providers` interface.
3. **Cross-domain via public API** — Domain A cannot reach into Domain B's internals; it must use B's public API (`index.*`).
4. **Boundary validation** — External data must be parsed/validated at the boundary layer (runtime) before reaching service logic. The invariant is enforced; the validation library is your choice.

See [docs/LAYERS.md](docs/LAYERS.md) for the full guide.

## Agent-Readable Errors

All enforcement scripts produce structured, agent-readable errors:

```
[HARNESS:FAIL] layer-violation | src/billing/service.ts:7 | Backward layer import
  WHAT: File in 'service' layer imports from 'runtime' layer
  WHY:  Layers flow forward only: types -> config -> repo -> service -> runtime -> ui
  FIX:  Move the shared logic to the 'service' layer or earlier
  REF:  docs/LAYERS.md#forward-only-rule
```

## Supported Tools

| Tool | Config File | Support Level |
|------|-------------|--------------|
| Claude Code | `CLAUDE.md`, `.claude/` | Primary (full @-imports, commands, rules) |
| OpenAI Codex | `AGENTS.md` | Full (self-contained, flat format) |
| Gemini CLI | `AGENTS.md` | Full (self-contained, flat format) |
| GitHub Copilot | `.github/copilot-instructions.md` | Basic (instructions + path-specific) |
| Cursor | `.cursor/rules/*.mdc` | Basic (self-contained rules) |

## Stack Support

Auto-detects your project language from marker files (`package.json`, `pyproject.toml`, `go.mod`, etc.). Override in `harness.json`:

```json
{ "stack": "typescript" }
```

## Prerequisites

- **bash** (4.0+)
- **jq** — the only non-POSIX dependency
- **git** — for hooks and CI

## File Tree

See [harness.json](harness.json) for the complete manifest of all ~75 files with metadata.

## Examples

- [TypeScript API](examples/typescript-api/) — REST API with users, billing, orders domains
- [Python ML](examples/python-ml/) — ML project with data-pipeline, models, serving domains
- [Go Service](examples/go-service/) — Microservice with api, storage, worker domains

## License

MIT — See [LICENSE](LICENSE).
