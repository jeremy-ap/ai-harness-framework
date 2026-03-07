#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"

# --- CLAUDE.md checks ---
CLAUDE_MD="$ROOT/CLAUDE.md"
if [[ -f "$CLAUDE_MD" ]]; then
  harness_pass "claude-md-exists" "CLAUDE.md exists"

  line_count=$(wc -l < "$CLAUDE_MD" | tr -d ' ')
  if (( line_count > 300 )); then
    harness_fail "claude-md-length" "$CLAUDE_MD" "CLAUDE.md exceeds 300 lines" \
      "CLAUDE.md is ${line_count} lines (max 300)." \
      "Overly long agent config files reduce comprehension and increase token usage." \
      "Split detailed instructions into separate files and use @-imports." \
      "docs/DESIGN.md#agent-config"
  else
    harness_pass "claude-md-length" "CLAUDE.md is ${line_count} lines (within 300 limit)"
  fi

  # Check required sections
  for section in "Project Summary" "Key Commands" "Standards" "Workflow"; do
    if grep -qi "^#.*${section}" "$CLAUDE_MD"; then
      harness_pass "claude-md-section-${section// /-}" "CLAUDE.md has '${section}' section"
    else
      harness_fail "claude-md-section-${section// /-}" "$CLAUDE_MD" "Missing required section: ${section}" \
        "CLAUDE.md is missing a '${section}' section heading." \
        "Agent config files need standard sections for consistent onboarding." \
        "Add a markdown heading containing '${section}'." \
        "docs/DESIGN.md#claude-md-structure"
    fi
  done

  # Check @-imports resolve to actual files
  while IFS= read -r line; do
    import_path="${line#@}"
    import_path="${import_path## }"
    import_path="${import_path%% *}"
    if [[ -n "$import_path" ]]; then
      resolved="$ROOT/$import_path"
      if [[ -f "$resolved" || -d "$resolved" ]]; then
        harness_pass "claude-md-import" "@-import resolves: ${import_path}"
      else
        harness_fail "claude-md-import" "$CLAUDE_MD" "Broken @-import: ${import_path}" \
          "CLAUDE.md references '${import_path}' via @-import but it does not exist." \
          "@-imports must point to real files so agents can read them." \
          "Fix the path or create the missing file." \
          "docs/DESIGN.md#at-imports"
      fi
    fi
  done < <(grep -E '^\s*@' "$CLAUDE_MD" 2>/dev/null || true)

  # Check for unfilled placeholders
  if is_template "$CLAUDE_MD"; then
    placeholders=$(list_placeholders "$CLAUDE_MD")
    harness_warn "claude-md-placeholders" "$CLAUDE_MD" "Unfilled placeholders found" \
      "CLAUDE.md contains template tokens: ${placeholders//$'\n'/, }" \
      "Replace {{PLACEHOLDER}} tokens with actual values." \
      "docs/DESIGN.md#templates"
  fi
else
  harness_fail "claude-md-exists" "$ROOT" "CLAUDE.md not found" \
    "No CLAUDE.md found at project root." \
    "CLAUDE.md is required for agent-assisted development." \
    "Create CLAUDE.md with sections: Project Summary, Key Commands, Standards, Workflow." \
    "docs/DESIGN.md#claude-md-structure"
fi

# --- AGENTS.md checks ---
AGENTS_MD="$ROOT/AGENTS.md"
if [[ -f "$AGENTS_MD" ]]; then
  harness_pass "agents-md-exists" "AGENTS.md exists"

  line_count=$(wc -l < "$AGENTS_MD" | tr -d ' ')
  if (( line_count > 200 )); then
    harness_fail "agents-md-length" "$AGENTS_MD" "AGENTS.md exceeds 200 lines" \
      "AGENTS.md is ${line_count} lines (max 200)." \
      "Overly long agent config files reduce comprehension." \
      "Trim or split into separate referenced files." \
      "docs/DESIGN.md#agent-config"
  else
    harness_pass "agents-md-length" "AGENTS.md is ${line_count} lines (within 200 limit)"
  fi

  for section in "Project Summary" "Commands" "Verification Checklist"; do
    if grep -qi "^#.*${section}" "$AGENTS_MD"; then
      harness_pass "agents-md-section-${section// /-}" "AGENTS.md has '${section}' section"
    else
      harness_fail "agents-md-section-${section// /-}" "$AGENTS_MD" "Missing required section: ${section}" \
        "AGENTS.md is missing a '${section}' section heading." \
        "Agent config files need standard sections for consistent onboarding." \
        "Add a markdown heading containing '${section}'." \
        "docs/DESIGN.md#agents-md-structure"
    fi
  done
else
  harness_fail "agents-md-exists" "$ROOT" "AGENTS.md not found" \
    "No AGENTS.md found at project root." \
    "AGENTS.md is required for multi-agent coordination." \
    "Create AGENTS.md with sections: Project Summary, Commands, Verification Checklist." \
    "docs/DESIGN.md#agents-md-structure"
fi

# --- .claude/settings.json check ---
SETTINGS="$ROOT/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  harness_pass "claude-settings" ".claude/settings.json exists"
else
  harness_fail "claude-settings" "$ROOT/.claude/" "Missing .claude/settings.json" \
    ".claude/settings.json not found." \
    "Claude settings file configures agent permissions and behavior." \
    "Create .claude/settings.json with appropriate configuration." \
    "docs/DESIGN.md#claude-settings"
fi

harness_summary "Agent Config Lint"
