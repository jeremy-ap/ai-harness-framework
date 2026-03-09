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

    # --- Verification JSON checks for active plans ---
    verify_json="${plan%.md}.verify.json"
    if [[ -f "$verify_json" ]]; then
      verify_name="$(basename "$verify_json")"

      # Validate JSON syntax
      if ! jq empty "$verify_json" 2>/dev/null; then
        harness_fail "verify-json-syntax" "$verify_json" "Invalid JSON syntax" \
          "Verification file '${verify_name}' is not valid JSON." \
          "Fix JSON syntax errors in the file." \
          "Run 'jq . ${verify_json}' to see the error." \
          "docs/exec-plans/README.md#verification-tests"
      else
        # Check required fields
        has_plan=$(jq -r 'has("plan")' "$verify_json")
        has_created=$(jq -r 'has("created")' "$verify_json")
        has_updated=$(jq -r 'has("updated")' "$verify_json")
        has_tests=$(jq -r 'has("tests")' "$verify_json")

        if [[ "$has_plan" != "true" || "$has_created" != "true" || "$has_updated" != "true" || "$has_tests" != "true" ]]; then
          harness_fail "verify-json-fields" "$verify_json" "Missing required fields" \
            "Verification file '${verify_name}' is missing required fields." \
            "Required fields: plan, created, updated, tests." \
            "Ensure all required fields are present in the JSON." \
            "docs/exec-plans/README.md#verification-tests"
        else
          # Check plan field matches companion .md filename
          json_plan=$(jq -r '.plan' "$verify_json")
          if [[ "$json_plan" != "$plan_name" ]]; then
            harness_fail "verify-json-plan-match" "$verify_json" "Plan field does not match filename" \
              "Verification file '${verify_name}' has plan='${json_plan}' but companion is '${plan_name}'." \
              "The 'plan' field must match the companion .md filename." \
              "Update the 'plan' field to '${plan_name}'." \
              "docs/exec-plans/README.md#verification-tests"
          else
            harness_pass "verify-json-plan-match" "${verify_name} plan field matches companion"
          fi

          # Check tests array is non-empty
          test_count=$(jq '.tests | length' "$verify_json")
          if (( test_count == 0 )); then
            harness_fail "verify-json-tests-empty" "$verify_json" "Tests array is empty" \
              "Verification file '${verify_name}' has no tests." \
              "Add at least one verification test." \
              "Use docs/exec-plans/VERIFY_TEMPLATE.json as a reference." \
              "docs/exec-plans/README.md#verification-tests"
          else
            harness_pass "verify-json-tests" "${verify_name} has ${test_count} verification test(s)"
          fi

          # Check passing tests have non-empty evidence
          passing_no_evidence=$(jq '[.tests[] | select(.passes == true and (.evidence == null or .evidence == ""))] | length' "$verify_json")
          if (( passing_no_evidence > 0 )); then
            harness_fail "verify-json-evidence" "$verify_json" "Passing tests missing evidence" \
              "${passing_no_evidence} test(s) in '${verify_name}' have passes=true but no evidence." \
              "Every passing test must include an 'evidence' field explaining what was verified." \
              "Add specific evidence for each passing test." \
              "docs/exec-plans/README.md#verification-tests"
          else
            passing_count=$(jq '[.tests[] | select(.passes == true)] | length' "$verify_json")
            if (( passing_count > 0 )); then
              harness_pass "verify-json-evidence" "${verify_name} — all passing tests have evidence"
            fi
          fi
        fi
      fi
    else
      harness_warn "verify-json-missing" "$plan" "No companion .verify.json" \
        "Active plan '${plan_name}' has no companion verification file." \
        "Create a .verify.json file to define structured acceptance tests." \
        "Use docs/exec-plans/VERIFY_TEMPLATE.json as a starting point." \
        "docs/exec-plans/README.md#verification-tests"
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

    # --- Verification JSON checks for completed plans ---
    verify_json="${plan%.md}.verify.json"
    if [[ -f "$verify_json" ]]; then
      verify_name="$(basename "$verify_json")"

      if jq empty "$verify_json" 2>/dev/null; then
        failing_count=$(jq '[.tests[] | select(.passes == false)] | length' "$verify_json")
        if (( failing_count > 0 )); then
          harness_fail "verify-completed-passing" "$verify_json" "Completed plan has failing verification tests" \
            "Completed plan '${plan_name}' has ${failing_count} failing verification test(s)." \
            "All verification tests must pass before a plan is moved to completed/." \
            "Run '/verify-plan' to check and update test status, or fix the failing tests." \
            "docs/exec-plans/README.md#verification-tests"
        else
          total_count=$(jq '.tests | length' "$verify_json")
          harness_pass "verify-completed-passing" "${verify_name} — all ${total_count} tests pass"
        fi

        # Check passing tests have evidence even in completed
        passing_no_evidence=$(jq '[.tests[] | select(.passes == true and (.evidence == null or .evidence == ""))] | length' "$verify_json")
        if (( passing_no_evidence > 0 )); then
          harness_fail "verify-completed-evidence" "$verify_json" "Passing tests missing evidence" \
            "${passing_no_evidence} test(s) in '${verify_name}' have passes=true but no evidence." \
            "Every passing test must include an 'evidence' field explaining what was verified." \
            "Add specific evidence for each passing test." \
            "docs/exec-plans/README.md#verification-tests"
        fi
      fi
    fi
  done < <(find "$COMPLETED_DIR" -name "*.md" -type f 2>/dev/null)
else
  harness_info "No docs/exec-plans/completed/ directory found, skipping."
fi

harness_summary "Exec Plan Lint"
