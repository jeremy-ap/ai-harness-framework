# /progress — Update Progress Log

Update `docs/PROGRESS.md` with a summary of recent work.

## Steps

1. Read `docs/PROGRESS.md` to see the current status and last entry date
2. Run `git log --oneline -20` to see recent commits since the last entry
3. Check `docs/exec-plans/completed/` for any plans completed since the last entry
4. Check `docs/exec-plans/active/` for in-progress work
5. Draft a new log entry with today's date:
   - 2-5 bullet points of concrete outcomes (features added, bugs fixed, infrastructure changes)
   - Key decisions made (if any)
   - Current state and next steps
6. Prepend the new entry to the Log section (newest first)
7. Update the **Current Status** section at the top (state, last updated date)
8. Show the draft to the user and confirm before saving

## Entry Format

```markdown
### YYYY-MM-DD

**Brief title of what was accomplished**

- Concrete outcome 1
- Concrete outcome 2
- Concrete outcome 3

**Decisions:** Key decision made and why (or "None" if no significant decisions).

**Next steps:** What should happen next.
```

## Guidelines

- **Be concise:** 5-10 lines per entry. This is a summary, not a changelog.
- **Focus on outcomes:** "Added invoice generation endpoint" not "edited 5 files"
- **Reference exec-plans:** If an exec-plan was completed, mention it by name
- **Skip trivial work:** Don't log typo fixes, formatting changes, or dependency bumps
- **Keep Current Status honest:** It should reflect reality, not aspirations
