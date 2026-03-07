# Acme ML Platform — Agent Configuration

## Purpose
This file configures AI coding agents for the Acme ML Platform. Self-contained — no external file references needed.

## Project Summary
Machine learning platform for Acme Corp. Handles data ingestion/transformation pipelines, model training/evaluation, and model serving via REST API. Built with Python, FastAPI, and PyTorch.

## Commands
```bash
# Test
pytest                          # all tests
pytest tests/<path> -v          # single test

# Lint & format
ruff check .
ruff format .
mypy src/

# Harness
./scripts/harness-doctor.sh
```

## Architecture
Layered domain architecture with three domains: `data_pipeline`, `models`, `serving`. Each domain follows: Types -> Config -> Repo -> Service -> Runtime. Layers import forward-only. Cross-cutting concerns (auth, telemetry, logging) enter via each domain's `providers.py`. Cross-domain imports use public APIs (`__init__.py`). See `architecture.json` for full specification.

## Code Conventions
- Python 3.11+ with strict mypy type checking
- Type hints on all public functions and methods
- Docstrings on all public classes and functions (Google style)
- snake_case for functions/variables, PascalCase for classes
- Imports sorted with isort (ruff handles this)
- No mutable default arguments

## Testing Requirements
- pytest with fixtures for shared setup
- Test files: `tests/test_<module>.py`
- Mock external services and I/O
- Use `pytest.mark.slow` for tests >5 seconds
- Parameterized tests for data-driven scenarios

## Verification Checklist
Before considering any task complete, verify ALL of the following:

- [ ] Code passes type checking (`mypy src/`)
- [ ] All existing tests pass (`pytest`)
- [ ] New code has corresponding tests in `tests/`
- [ ] Tests verify behavior with meaningful assertions
- [ ] No regressions in existing functionality
- [ ] Architecture boundaries respected (`./scripts/lint-architecture.sh`)
- [ ] Documentation updated if public API changed
- [ ] No hardcoded paths, credentials, or magic numbers

## Workflow
1. Read the task or exec-plan
2. Understand the affected domains and layers
3. Make changes in small, testable increments
4. Run tests after each change
5. Verify architecture boundaries
6. Update docs if public API changes
7. Run `./scripts/harness-doctor.sh` before final commit
