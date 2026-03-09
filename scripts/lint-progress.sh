#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"
PROGRESS_FILE="$ROOT/docs/PROGRESS.md"

WARN_THRESHOLD=3
FAIL_THRESHOLD=10

harness_info "Checking progress log..."

# --- Check PROGRESS.md exists ---
if [[ ! -f "$PROGRESS_FILE" ]]; then
  harness_fail "progress-exists" "docs/PROGRESS.md" "Progress log not found" \
    "docs/PROGRESS.md does not exist." \
    "The progress log gives agents instant orientation on recent project history." \
    "Create docs/PROGRESS.md or run /init to set up the project." \
    "docs/PROGRESS.md"
  harness_summary "Progress Log"
  exit $?
fi

harness_pass "progress-exists" "docs/PROGRESS.md exists"

# --- Extract latest entry date ---
# Look for ### YYYY-MM-DD headings
latest_date=$(grep -E '^### [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROGRESS_FILE" | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "")

if [[ -z "$latest_date" ]]; then
  harness_warn "progress-date" "docs/PROGRESS.md" "No dated entries found" \
    "Could not find any ### YYYY-MM-DD entries in PROGRESS.md." \
    "Run /progress to add a dated entry." \
    "docs/PROGRESS.md"
  harness_summary "Progress Log"
  exit $?
fi

harness_pass "progress-date" "Latest entry: ${latest_date}"

# --- Count commits since last entry ---
# Use git log to count commits after the entry date
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  commits_since=$(git log --after="${latest_date}" --oneline 2>/dev/null | wc -l | tr -d ' ')

  if (( commits_since >= FAIL_THRESHOLD )); then
    harness_fail "progress-stale" "docs/PROGRESS.md" "Progress log is stale (${commits_since} commits behind)" \
      "There are ${commits_since} commits since the last progress entry on ${latest_date}." \
      "Stale progress logs defeat their purpose — future sessions cannot orient quickly." \
      "Run /progress to add an entry summarizing recent work." \
      "docs/PROGRESS.md"
  elif (( commits_since >= WARN_THRESHOLD )); then
    harness_warn "progress-stale" "docs/PROGRESS.md" "Progress log may be stale (${commits_since} commits behind)" \
      "${commits_since} commits since last entry on ${latest_date} (warn threshold: ${WARN_THRESHOLD})." \
      "Consider running /progress to add an entry." \
      "docs/PROGRESS.md"
  else
    harness_pass "progress-fresh" "Progress log is current (${commits_since} commits since ${latest_date})"
  fi
else
  harness_info "Not a git repository — skipping staleness check."
fi

harness_summary "Progress Log"
