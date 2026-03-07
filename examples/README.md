# Examples

Each directory contains a filled-in harness configuration for a specific technology stack. Use these as references when customizing the harness for your own project.

## Available Examples

| Example | Stack | Domains | Description |
|---------|-------|---------|-------------|
| [typescript-api/](typescript-api/) | TypeScript + Express | users, billing, orders | REST API with layered architecture |
| [python-ml/](python-ml/) | Python + FastAPI | data-pipeline, models, serving | ML platform with training and serving |
| [go-service/](go-service/) | Go + net/http | api, storage, worker | Microservice with background jobs |

## What's in Each Example

Each example includes three filled-in files (no `{{PLACEHOLDER}}` tokens remaining):

- **CLAUDE.md** — Claude Code configuration with real commands and directory descriptions
- **AGENTS.md** — Cross-tool agent configuration with verification checklist
- **architecture.json** — Fully defined domain boundaries and layer structure

## How to Use

1. Pick the example closest to your stack
2. Copy the relevant files into your project after running `install.sh`
3. Replace the example-specific values with your project's actual values
4. Use the structure and phrasing as a model for your own configuration
