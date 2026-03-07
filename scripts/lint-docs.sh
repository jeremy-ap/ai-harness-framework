#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"

# --- Check internal markdown links ---
harness_info "Checking internal markdown links..."
while IFS= read -r mdfile; do
  while IFS= read -r match; do
    # Extract path from [text](path) — skip URLs and anchors
    link_path=$(echo "$match" | sed -E 's/.*\]\(([^)#]+).*/\1/')
    # Skip external URLs
    [[ "$link_path" =~ ^https?:// ]] && continue
    [[ "$link_path" =~ ^mailto: ]] && continue
    [[ -z "$link_path" ]] && continue

    # Resolve relative to the markdown file's directory
    mddir="$(dirname "$mdfile")"
    resolved="$mddir/$link_path"
    if [[ ! -f "$resolved" && ! -d "$resolved" ]]; then
      harness_fail "broken-link" "$mdfile" "Broken internal link: ${link_path}" \
        "Link target '${link_path}' does not exist." \
        "Broken links confuse readers and agents." \
        "Fix the path or remove the broken link." \
        "docs/DESIGN.md#documentation"
    fi
  done < <(grep -oE '\[[^]]*\]\([^)]+\)' "$mdfile" 2>/dev/null || true)
done < <(find "$ROOT/docs" -name "*.md" -type f 2>/dev/null || true)
harness_pass "link-check-done" "Internal link scan complete"

# --- Check index files are in sync ---
harness_info "Checking index file sync..."
while IFS= read -r index_file; do
  index_dir="$(dirname "$index_file")"
  while IFS= read -r sibling; do
    basename_sibling="$(basename "$sibling")"
    [[ "$basename_sibling" == "index.md" ]] && continue
    [[ "$basename_sibling" == "TEMPLATE.md" ]] && continue
    if ! grep -q "$basename_sibling" "$index_file" 2>/dev/null; then
      harness_warn "index-sync" "$index_file" "Index missing reference to ${basename_sibling}" \
        "File '${basename_sibling}' exists in $(basename "$index_dir")/ but is not referenced in index.md." \
        "Add a reference to '${basename_sibling}' in the index file." \
        "docs/DESIGN.md#documentation"
    fi
  done < <(find "$index_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null || true)
done < <(find "$ROOT/docs" -name "index.md" -type f 2>/dev/null || true)
harness_pass "index-sync-done" "Index sync scan complete"

# --- Check QUALITY_SCORE.md freshness ---
harness_info "Checking QUALITY_SCORE.md freshness..."
QUALITY_SCORE="$ROOT/docs/QUALITY_SCORE.md"
if [[ -f "$QUALITY_SCORE" ]]; then
  if command -v stat &>/dev/null; then
    # Get modification time in seconds since epoch
    if [[ "$(uname)" == "Darwin" ]]; then
      mod_time=$(stat -f %m "$QUALITY_SCORE")
    else
      mod_time=$(stat -c %Y "$QUALITY_SCORE")
    fi
    now=$(date +%s)
    age_days=$(( (now - mod_time) / 86400 ))
    if (( age_days > 7 )); then
      harness_warn "quality-score-stale" "$QUALITY_SCORE" "QUALITY_SCORE.md is ${age_days} days old" \
        "Quality score was last updated ${age_days} days ago (threshold: 7 days)." \
        "Run scripts/quality-score.sh to regenerate." \
        "docs/DESIGN.md#quality-score"
    else
      harness_pass "quality-score-fresh" "QUALITY_SCORE.md is fresh (${age_days} days old)"
    fi
  fi
else
  harness_warn "quality-score-missing" "$ROOT/docs/" "QUALITY_SCORE.md not found" \
    "No quality score file found." \
    "Run scripts/quality-score.sh to generate it." \
    "docs/DESIGN.md#quality-score"
fi

# --- Detect broken @-import references in all markdown files ---
harness_info "Checking @-import references..."
while IFS= read -r mdfile; do
  while IFS= read -r line; do
    import_path="${line#@}"
    import_path="${import_path## }"
    import_path="${import_path%% *}"
    if [[ -n "$import_path" ]]; then
      resolved="$ROOT/$import_path"
      if [[ ! -f "$resolved" && ! -d "$resolved" ]]; then
        harness_fail "broken-at-import" "$mdfile" "Broken @-import: ${import_path}" \
          "File references '${import_path}' via @-import but it does not exist." \
          "@-imports must point to real files." \
          "Fix the path or create the missing file." \
          "docs/DESIGN.md#at-imports"
      fi
    fi
  done < <(grep -E '^\s*@' "$mdfile" 2>/dev/null || true)
done < <(find "$ROOT" -name "*.md" -type f -not -path "*/node_modules/*" 2>/dev/null || true)
harness_pass "at-import-done" "@-import reference scan complete"

harness_summary "Documentation Lint"
