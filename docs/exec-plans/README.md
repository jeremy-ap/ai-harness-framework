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

## Directory Structure

```
exec-plans/
├── README.md          # This file
├── TEMPLATE.md        # Template for new plans
├── active/            # Plans currently being executed
│   └── .gitkeep
└── completed/         # Finished plans (historical record)
    └── .gitkeep
```
