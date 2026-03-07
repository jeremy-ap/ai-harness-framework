# Contributing

> Replace all `{{PLACEHOLDER}}` values with project-specific content.

## Getting Started

1. Clone the repository: `git clone {{REPO_URL}}`
2. Install dependencies: `{{INSTALL_COMMAND}}`
3. Run the test suite: `{{TEST_COMMAND}}`
4. Read the architecture docs: [DESIGN.md](./DESIGN.md), [LAYERS.md](./LAYERS.md)

## Human Workflow

### Making Changes

1. Create a branch from `{{DEFAULT_BRANCH}}`: `git checkout -b your-branch-name`
2. Make your changes following the architecture rules in [LAYERS.md](./LAYERS.md)
3. Write or update tests (see [TESTING.md](./TESTING.md))
4. Run the quality checks: `{{QUALITY_CHECK_COMMAND}}`
5. Commit with a clear message describing what and why
6. Open a pull request against `{{DEFAULT_BRANCH}}`

### Commit Messages

- Use present tense: "add feature" not "added feature"
- First line: concise summary (under 72 characters)
- Body (optional): explain why, not what

### Pull Request Checklist

- [ ] Tests pass locally
- [ ] Architecture check passes (`scripts/check-architecture.sh`)
- [ ] New code has tests with meaningful assertions
- [ ] Documentation updated if behavior changed
- [ ] No secrets or credentials committed

### Code Review

- Every PR requires at least {{REVIEW_COUNT}} approval(s)
- Reviewers check for correctness, security, and architecture compliance
- Address all comments before merging

## Agent Workflow

AI agents contributing to this project must follow the same rules as human
contributors, with additional constraints:

### Before Making Changes

1. Read relevant documentation: `CLAUDE.md`, `LAYERS.md`, `TESTING.md`
2. Read `architecture.json` to understand module boundaries
3. Read the existing code before modifying it

### While Making Changes

1. Follow the layer chain and dependency rules in [LAYERS.md](./LAYERS.md)
2. Use the providers pattern for cross-cutting concerns
3. Do not import across domain boundaries except through public APIs
4. Write tests with meaningful assertions for all new code
5. Run `scripts/check-architecture.sh` after making changes

### Exec Plans

For multi-step tasks, create an exec plan in `docs/exec-plans/active/` using
the [template](./exec-plans/TEMPLATE.md). Update the plan as work progresses
and move it to `completed/` when done.

### What Agents Should NOT Do

- Do not bypass architecture rules for convenience
- Do not create tests without assertions
- Do not commit without running checks
- Do not modify `architecture.json` without explicit approval
- Do not skip reading existing code before making changes

## Project Structure

{{PROJECT_STRUCTURE_OVERVIEW}}

See [DESIGN.md](./DESIGN.md) for the full architecture overview.

## Questions

- Check existing docs in `docs/` first
- Review design decisions in `docs/design-docs/`
- Ask in {{COMMUNICATION_CHANNEL}}
