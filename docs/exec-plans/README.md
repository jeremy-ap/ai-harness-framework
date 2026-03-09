# Execution Plans

Execution plans are structured task plans for agent execution. They break
complex work into discrete, trackable steps with clear acceptance criteria.

## What Is an Exec Plan?

An exec plan is a markdown document with YAML frontmatter that describes a
multi-step task. It serves as both a plan and a record of execution — agents
update it as they work, and it becomes documentation of what was done when
complete.

## Format

Each exec plan uses YAML frontmatter followed by a markdown body:

```yaml
---
title: "Plan Title"
status: active
created: 2024-01-15
updated: 2024-01-15
owner: "agent-name"
---
```

The body contains:
- **Objective**: What the plan accomplishes
- **Steps**: Checkbox list of discrete tasks
- **Acceptance Criteria**: How to verify the plan is complete
- **Notes**: Context, blockers, and decisions made during execution
- **Summary**: Filled in on completion

See [TEMPLATE.md](./TEMPLATE.md) for the full template.

## Lifecycle

1. **Create** — Copy `TEMPLATE.md` to `active/plan-name.md`
2. **Execute** — Work through steps, checking boxes as they complete
3. **Update** — Add notes about decisions, blockers, and changes
4. **Complete** — Fill in the summary, change status to `completed`
5. **Archive** — Move the file from `active/` to `completed/`

## How Agents Use Exec Plans

1. Before starting complex work, create a plan in `active/`
2. Check off steps as you complete them
3. Add notes when you encounter blockers or make decisions
4. When all steps are done, verify acceptance criteria
5. Fill in the summary section
6. Move the file to `completed/`

Exec plans keep work transparent and recoverable. If an agent is interrupted,
another agent (or a human) can pick up where it left off by reading the plan.

## Verification Tests {#verification-tests}

Each exec plan has a companion `.verify.json` file that provides structured,
machine-parseable proof that acceptance criteria have been met. This replaces
prose checkboxes, which are easily fudged by bulk-checking.

### Why JSON Instead of Markdown Checkboxes?

- JSON with `"passes": false` fields forces deliberate, per-test updates
- The `evidence` field requires specific proof of what was verified
- `lint-exec-plans.sh` can enforce that completed plans have all-passing tests
- The verification file becomes a structured record of what was checked and how

### Format

```json
{
  "plan": "NNN-plan-name.md",
  "created": "YYYY-MM-DD",
  "updated": "YYYY-MM-DD",
  "tests": [
    {
      "id": "func-001",
      "category": "functional",
      "description": "What this test verifies",
      "steps": ["Step 1", "Step 2"],
      "passes": false,
      "evidence": "Required when passes is true"
    }
  ]
}
```

**Fields:**
- `plan` — Filename of the companion `.md` plan
- `created` / `updated` — Date strings (YYYY-MM-DD)
- `tests` — Array of test objects:
  - `id` — Unique identifier (e.g., `func-001`, `arch-001`)
  - `category` — One of: `functional`, `integration`, `edge-case`, `architecture`, `documentation`
  - `description` — What the test verifies
  - `steps` — Array of steps to execute
  - `passes` — Boolean, starts as `false`
  - `evidence` — String, required when `passes` is `true`

### Lifecycle

1. **Created with plan** — `/plan` generates both `.md` and `.verify.json`
2. **Updated during work** — `/verify-plan` runs tests and records evidence
3. **Enforced at completion** — `lint-exec-plans.sh` fails if completed plans have failing tests

### Categories

| Prefix | Category | What it verifies |
|--------|----------|------------------|
| `func-` | functional | Does the feature work correctly? |
| `integ-` | integration | Do components work together? |
| `edge-` | edge-case | Are boundary conditions handled? |
| `arch-` | architecture | Do changes follow project structure rules? |
| `doc-` | documentation | Are docs updated to match changes? |

See [VERIFY_TEMPLATE.json](./VERIFY_TEMPLATE.json) for the template.

## Directory Structure

```
exec-plans/
├── README.md              # This file
├── TEMPLATE.md            # Template for new plans
├── VERIFY_TEMPLATE.json   # Template for verification files
├── active/                # Plans currently being executed
│   ├── NNN-name.md        # Exec plan
│   ├── NNN-name.verify.json  # Companion verification tests
│   └── .gitkeep
└── completed/             # Finished plans (historical record)
    ├── NNN-name.md
    ├── NNN-name.verify.json
    └── .gitkeep
```
