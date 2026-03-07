# References

This directory holds reformatted library and API documentation optimized for
agent consumption. Agents read these files to understand external dependencies
without needing to browse the web.

## How to Add a Reference

1. Find the official documentation for the library or API.
2. Create a new markdown file: `library-name.md`
3. Reformat the documentation following the guidelines below.
4. Commit the file to this directory.

## Formatting Guidelines

### Structure

```markdown
# Library Name vX.Y.Z

> One-line description of what this library does.

## Quick Start
[Minimal working example]

## Core API
[Most commonly used functions/methods with signatures and examples]

## Configuration
[Configuration options with defaults]

## Common Patterns
[Frequently used patterns and idioms]

## Gotchas
[Non-obvious behavior, breaking changes, common mistakes]
```

### Rules

- **Include version numbers.** Agents need to know which version the docs
  apply to. Update when the project upgrades.
- **Lead with examples.** Show usage before explaining theory.
- **Keep it concise.** Strip marketing language, tutorials for beginners, and
  content not relevant to this project's usage.
- **Use code blocks.** All function signatures and examples in fenced code
  blocks with language tags.
- **Document gotchas prominently.** If something is surprising or a common
  source of bugs, call it out explicitly.
- **One file per library.** Do not combine multiple libraries into one file.

### Converting API Docs

When converting official API documentation:

1. Extract only the APIs this project actually uses (or is likely to use)
2. Simplify type signatures — remove overloads that are not relevant
3. Add practical examples from this project's codebase where possible
4. Note any project-specific configuration or wrappers

## Maintenance

- When upgrading a dependency, update its reference doc
- Delete reference docs for removed dependencies
- Review quarterly for staleness
