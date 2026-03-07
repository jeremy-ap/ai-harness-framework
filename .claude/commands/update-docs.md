# /update-docs — Regenerate Documentation

Update documentation to reflect current code state.

## Steps

1. Check for public API changes by comparing current state with docs
2. If `docs/DESIGN.md` exists and architecture changed, update the component map and data flow sections
3. Run `./scripts/quality-score.sh` to regenerate `docs/QUALITY_SCORE.md`
4. Run `./scripts/generate-dependency-graph.sh` to update dependency visualization
5. Run `./scripts/lint-docs.sh` to check for broken links or stale references
6. Fix any documentation issues found
7. Report what was updated
