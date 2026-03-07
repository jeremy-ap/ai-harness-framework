#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"
ACTIVE_DIR="$ROOT/docs/exec-plans/active"
COMPLETED_DIR="$ROOT/docs/exec-plans/completed"

# --- Check active plans ---
harness_info "Checking active execution plans..."
if [[ -d "$ACTIVE_DIR" ]]; then
  found_active=0
  while IFS= read -r plan; do
    [[ -z "$plan" ]] && continue
    found_active=$((found_active + 1))
    plan_name="$(basename "$plan")"

    # Check YAML frontmatter exists (between --- markers)
    if ! head -1 "$plan" | grep -q '^---$'; then
      harness_fail "plan-frontmatter" "$plan" "Missing YAML frontmatter" \
        "Active plan '${plan_name}' has no YAML frontmatter block." \
        "Plans need frontmatter for metadata (title, status, owner, dates)." \
        "Add YAML frontmatter between --- markers at the top of the file." \
        "docs/DESIGN.md#exec-plans"
      continue
    fi

    # Extract frontmatter (between first and second ---)
    frontmatter=$(sed -n '1,/^---$/p' "$plan" | tail -n +2 | head -n -1)
    if [[ -z "$frontmatter" ]]; then
      # Try alternate: content between line 1 (---) and next ---
      frontmatter=$(awk 'NR==1{next} /^---$/{exit} {print}' "$plan")
    fi

    # Check required fields
    for field in title status created updated owner; do
      if echo "$frontmatter" | grep -qE "^${field}:"; then
        harness_pass "plan-field-${field}" "${plan_name} has '${field}' field"
      else
        harness_fail "plan-field-${field}" "$plan" "Missing frontmatter field: ${field}" \
          "Active plan '${plan_name}' is missing the '${field}' field." \
          "All active plans require: title, status, created, updated, owner." \
          "Add '${field}: <value>' to the YAML frontmatter." \
          "docs/DESIGN.md#exec-plans"
      fi
    done

    # Check staleness (warn if 'updated' is older than 30 days)
    updated_value=$(echo "$frontmatter" | grep -E '^updated:' | sed 's/^updated:\s*//' | tr -d '"' | tr -d "'")
    if [[ -n "$updated_value" ]]; then
      # Try to parse date
      updated_epoch=$(date -j -f "%Y-%m-%d" "$updated_value" +%s 2>/dev/null || date -d "$updated_value" +%s 2>/dev/null || echo "")
      if [[ -n "$updated_epoch" ]]; then
        now=$(date +%s)
        age_days=$(( (now - updated_epoch) / 86400 ))
        if (( age_days > 30 )); then
          harness_warn "plan-stale" "$plan" "Active plan is ${age_days} days old" \
            "Plan '${plan_name}' was last updated ${age_days} days ago (threshold: 30 days)." \
            "Review and update the plan, or move it to completed/ if done." \
            "docs/DESIGN.md#exec-plans"
        else
          harness_pass "plan-fresh" "${plan_name} is fresh (${age_days} days)"
        fi
      fi
    fi
  done < <(find "$ACTIVE_DIR" -name "*.md" -type f 2>/dev/null)

  if (( found_active == 0 )); then
    harness_info "No active execution plans found."
  fi
else
  harness_info "No docs/exec-plans/active/ directory found, skipping."
fi

# --- Check completed plans ---
harness_info "Checking completed execution plans..."
if [[ -d "$COMPLETED_DIR" ]]; then
  while IFS= read -r plan; do
    [[ -z "$plan" ]] && continue
    plan_name="$(basename "$plan")"

    if grep -qi "^#.*Summary\|^## Summary" "$plan" 2>/dev/null; then
      harness_pass "plan-summary" "${plan_name} has Summary section"
    else
      harness_warn "plan-no-summary" "$plan" "Completed plan missing Summary section" \
        "Completed plan '${plan_name}' has no Summary section." \
        "Add a '## Summary' section documenting outcomes." \
        "docs/DESIGN.md#exec-plans"
    fi
  done < <(find "$COMPLETED_DIR" -name "*.md" -type f 2>/dev/null)
else
  harness_info "No docs/exec-plans/completed/ directory found, skipping."
fi

harness_summary "Exec Plan Lint"
