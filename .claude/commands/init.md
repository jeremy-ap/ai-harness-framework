# /init — Guided Project Setup

Set up a freshly installed harness by interviewing the user and filling all template placeholders.

## Before Starting

1. Run `./scripts/list-placeholders.sh --json` to see what needs to be filled. Parse the output to count unfilled placeholders and identify which files need updates.
2. Detect the project stack by checking for marker files:
   - `package.json` + `tsconfig.json` → TypeScript
   - `package.json` (no tsconfig) → JavaScript
   - `pyproject.toml` / `setup.py` / `requirements.txt` → Python
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pom.xml` / `build.gradle` / `build.gradle.kts` → Java
3. Read git config for auto-detectable values:
   - `git config user.name` → AUTHOR
   - `git branch --show-current` → DEFAULT_BRANCH (fallback: `main`)
   - `git remote get-url origin 2>/dev/null` → REPO_URL (fallback: ask user)
4. Present a summary to the user:
   > "I found N unfilled placeholders across M files. I'll walk you through setup in 6 phases — I can auto-detect many values from your project."
5. Ask: "Ready to begin? I'll start with the essentials and we can skip optional sections."

## Phase 1: Project Identity

**Fills:** CLAUDE.md, AGENTS.md, .github/copilot-instructions.md, .cursor/rules/general.mdc, docs/DESIGN.md, docs/CONTRIBUTING.md

Ask the user (show auto-detected defaults in parentheses):

1. **PROJECT_NAME** — "What is this project called?" (suggest: current directory name)
2. **PROJECT_SUMMARY** — "Describe this project in 1-2 sentences."
3. **LANGUAGE_VERSION** — "Confirm your language/runtime version." Based on detected stack, suggest:
   - TypeScript: read `tsconfig.json` target or `engines` in package.json → e.g. "TypeScript 5.x on Node.js 20"
   - Python: check `pyproject.toml` `requires-python` → e.g. "Python 3.12"
   - Go: check `go.mod` go directive → e.g. "Go 1.22"
4. **PROJECT_ROOT** — Derive automatically from directory name. Do not ask.

Apply replacements to all files listed above. `PROJECT_NAME` appears in ~6 files; replace it everywhere.

## Phase 2: Commands

**Fills:** CLAUDE.md, AGENTS.md, .github/copilot-instructions.md, .github/instructions/testing.instructions.md, .cursor/rules/general.mdc, .cursor/rules/testing.mdc, docs/CONTRIBUTING.md

Based on detected stack, present smart defaults and ask the user to confirm or customize each:

| Placeholder | TypeScript default | Python default | Go default |
|---|---|---|---|
| BUILD_COMMAND | `npm run build` | (none) | `go build ./...` |
| TEST_ALL_COMMAND | `npm test` | `pytest` | `go test ./...` |
| TEST_SINGLE_COMMAND | `npx jest <path> --no-coverage` | `pytest <path> -v` | `go test ./<pkg> -run <TestName>` |
| LINT_COMMAND | `npm run lint` | `ruff check .` | `golangci-lint run` |
| TYPECHECK_COMMAND | `npx tsc --noEmit` | `mypy src/` | (none) |
| TEST_FILE_PATTERN | `**/*.test.ts\|**/*.spec.ts` | `**/test_*.py\|**/*_test.py` | `**/*_test.go` |

Also derive:
- **INSTALL_COMMAND** — TypeScript: `npm install`, Python: `pip install -e ".[dev]"`, Go: `go mod download`
- **QUALITY_CHECK_COMMAND** — Always `./scripts/harness-doctor.sh`
- **TEST_COMMAND** — Same value as TEST_ALL_COMMAND

Present all defaults at once in a table and ask: "Do these look right? Change any that need adjusting."

Apply replacements to all files. TEST_ALL_COMMAND appears in ~7 files; replace everywhere.

## Phase 3: Code Structure

**Fills:** CLAUDE.md, AGENTS.md, .claude/commands/new-module.md, docs/DESIGN.md

Ask the user:

1. **SRC_DESCRIPTION** — "Describe your `src/` directory in a few words." (e.g., "Application source code organized by domain")
2. **TESTS_DESCRIPTION** — "Describe your `tests/` directory." (e.g., "Unit and integration tests mirroring src structure")
3. **TEST_DESCRIPTION** — Use the same value as TESTS_DESCRIPTION for DESIGN.md

Derive automatically (do not ask):
- **EXT** — From stack: TypeScript → `ts`, Python → `py`, Go → `go`, Rust → `rs`, Java → `java`

Apply to listed files.

## Phase 4: Architecture — Domains

**Fills:** architecture.json, docs/DESIGN.md

This is the most interactive phase. Guide the user:

1. Ask: "What are the main domains/modules in your project?" Give examples:
   - Web API: users, auth, billing, orders, notifications
   - CLI tool: parser, executor, formatter, config
   - ML pipeline: data, preprocessing, training, evaluation, serving
2. For each domain the user names, ask:
   - "What does the **[domain]** domain do?" (1 sentence)
   - "Which other domains does **[domain]** depend on?" (from the list)
3. Once all domains are collected, replace the entire `domains` block in `architecture.json`. For each domain, generate:
   ```json
   "domain_name": {
     "path": "src/domain_name",
     "description": "User's description",
     "layer_structure": {
       "types":   "src/domain_name/types.EXT",
       "config":  "src/domain_name/config.EXT",
       "repo":    "src/domain_name/repo.EXT",
       "service": "src/domain_name/service.EXT",
       "runtime": "src/domain_name/runtime.EXT",
       "ui":      "src/domain_name/ui/**"
     },
     "providers": "src/domain_name/providers.EXT",
     "allowed_domain_dependencies": ["list", "from", "user"],
     "public_api": "src/domain_name/index.EXT",
     "test_directory": "tests/domain_name"
   }
   ```
   Use the EXT derived in Phase 3.
4. Also remove the `{{DOMAIN}}` placeholder from the `providers` path_pattern in architecture.json — replace it with `*` or the first domain name.
5. Update the DESIGN.md component map with the actual domain directories.
6. Fill the DESIGN.md layer descriptions:
   - TYPES_DESCRIPTION, CONFIG_DESCRIPTION, REPO_DESCRIPTION, SERVICE_DESCRIPTION, RUNTIME_DESCRIPTION, UI_DESCRIPTION — generate sensible defaults based on the layer definitions in LAYERS.md, or ask the user if they want to customize.

## Phase 5: Repository & Team

**Fills:** docs/CONTRIBUTING.md, docs/design-docs/000-core-beliefs.md, docs/design-docs/index.md

Auto-detect (confirm with user):
- **DEFAULT_BRANCH** — from `git branch --show-current` or `main`
- **REPO_URL** — from `git remote get-url origin` or ask
- **AUTHOR** — from `git config user.name` or ask
- **DATE** — today's date (YYYY-MM-DD format)

Ask the user:
- **COMMUNICATION_CHANNEL** — "Where does your team discuss this project?" (e.g., "#project-name on Slack", "GitHub Discussions")
- **REVIEW_COUNT** — "How many PR approvals do you require?" (suggest: 1)
- **PROJECT_STRUCTURE_OVERVIEW** — Generate from the domains collected in Phase 4. Format as a directory tree showing `src/domain/` for each domain with a brief annotation.

Apply to listed files.

## Phase 6: Deep Documentation (offer to skip)

**Fills:** docs/DESIGN.md (remaining), docs/SECURITY.md, docs/RELIABILITY.md, docs/design-docs/000-core-beliefs.md (beliefs)

Tell the user:
> "The remaining placeholders are in detailed documentation files (security model, reliability model, core beliefs, design decisions). These require domain expertise and are best filled incrementally. Would you like to:
> 1. **Skip for now** — leave these for later (harness-doctor will remind you)
> 2. **Quick fill** — I'll ask a few high-level questions and generate first drafts"

### If skipping:
Leave all remaining placeholders in place. They will show up as warnings in harness-doctor.

### If quick-filling:
For **DESIGN.md** remaining placeholders:
- Ask about data flow (ingress, validation, business logic, data access, egress)
- Ask about 1-2 key design decisions
- Ask about external service dependencies
- Ask about explicit non-goals
- Mark generated content with `<!-- DRAFT: review and refine -->`

For **SECURITY.md**:
- Ask: "What are your main threat surfaces?" and "How do users authenticate?"
- Generate reasonable defaults for the rest
- Mark with `<!-- DRAFT: review and refine -->`

For **RELIABILITY.md**:
- Ask: "Do you have SLO targets?" and "What external dependencies need retry/circuit-breaker logic?"
- Generate reasonable defaults
- Mark with `<!-- DRAFT: review and refine -->`

For **000-core-beliefs.md**:
- Ask: "What are your team's 2-3 core beliefs about code quality, testing, and architecture?"
- Or offer to use the examples already in the template as starting points
- Mark with `<!-- DRAFT: review and refine -->`

## After Setup

1. Run `./scripts/list-placeholders.sh` to show remaining unfilled placeholders
2. Run `./scripts/harness-doctor.sh` to verify overall health
3. Report to the user:
   > "Filled X placeholders across Y files. [If remaining:] Z placeholders remain in deep documentation files — run `/doctor` anytime to check what's still unfilled."
4. Suggest next steps:
   - "Run `/doctor` anytime to check harness health"
   - "Run `/new-module <name>` to scaffold your first domain module"
   - If Phase 6 was skipped: "Fill detailed docs when ready — the templates have examples to guide you"

## Important Notes

- Always use the Edit tool to replace placeholders in existing files — never rewrite entire files
- When a placeholder appears multiple times in one file, use replace_all to catch all instances
- For architecture.json, the template has a single example domain entry — replace the entire `domains` object with real entries
- Confirm with the user before applying changes: show what will be filled and ask "Apply these changes?"
- If any phase seems irrelevant (e.g., no `src/` directory), ask the user and adapt
