# Acme ML Platform

## Project Summary
Machine learning platform for Acme Corp. Handles data ingestion/transformation pipelines, model training/evaluation, and model serving via REST API. Built with Python, FastAPI, and PyTorch.

## Key Commands
- Test (all): `pytest`
- Test (single): `pytest tests/<path> -v`
- Lint: `ruff check .`
- Format: `ruff format .`
- Type check: `mypy src/`
- Harness check: `./scripts/harness-doctor.sh`

## Key Directories
- `src/` — Application source, organized by domain
- `src/data_pipeline/` — Data ingestion and transformation
- `src/models/` — Model definitions, training, evaluation
- `src/serving/` — FastAPI endpoints for model inference
- `tests/` — Test files mirroring src/ structure
- `docs/` — Project documentation (@docs/DESIGN.md for architecture)
- `data/` — Data directory (git-ignored, see data/README.md)

## Standards
- Python 3.11+, strict mypy, ruff for linting
- Follow architecture boundaries in @architecture.json
- Always run tests before committing
- Type hints required on all public functions

## @-Imports (read when relevant)
@docs/DESIGN.md
@docs/LAYERS.md
@docs/TESTING.md
@docs/SECURITY.md
@.claude/rules/architecture-boundaries.md
@.claude/rules/commit-conventions.md

## Workflow
1. Check for active exec-plan in @docs/exec-plans/active/
2. Make changes in small, testable increments
3. Run tests after each change
4. Update docs if public API changes
5. Run `./scripts/harness-doctor.sh` before final commit
