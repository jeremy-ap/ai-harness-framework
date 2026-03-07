---
applyTo: "docs/**,**/*.md"
---

# Documentation Conventions

## Markdown Formatting
- Use ATX-style headings (`#`, `##`, `###`)
- Include a single H1 heading at the top of each document
- Use blank lines before and after headings, code blocks, and lists
- Keep line length reasonable (aim for under 120 characters in prose)
- Use fenced code blocks with language identifiers (e.g., ```typescript, ```python)

## Content Structure
- Start each document with a clear purpose statement
- Use headings to create a scannable hierarchy
- Prefer bullet lists for items without inherent order
- Use numbered lists for sequential steps or ranked items
- Include a brief summary or TL;DR for documents longer than 500 words

## Links and References
- Use relative links for internal project references (e.g., `[Design](./DESIGN.md)`)
- Do not use absolute file system paths in documentation
- Verify that all links resolve to existing files
- When referencing code, include the file path so readers can locate it

## Code Examples
- All code examples must be syntactically valid and runnable
- Include necessary imports and context so examples are self-contained
- Use realistic variable and function names, not `foo`/`bar`
- Add brief comments to explain non-obvious steps

## Maintenance
- Update documentation when the corresponding code changes
- Remove or update references to deleted or renamed files, functions, or APIs
- Date-stamp documents that describe decisions or point-in-time state
- Keep the document index (if any) in sync with actual files
