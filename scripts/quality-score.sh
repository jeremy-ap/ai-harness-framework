#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"
source "$SCRIPT_DIR/common/detect-stack.sh"

ROOT="$(harness_root)"
OUTPUT_FILE="$ROOT/docs/QUALITY_SCORE.md"

# Ensure docs directory exists
mkdir -p "$ROOT/docs"

# --- 1. Test coverage ratio ---
harness_info "Calculating test coverage ratio..."
IFS=',' read -ra exts <<< "$HARNESS_SOURCE_EXTENSIONS"
source_count=0
test_count=0

if [[ -d "$ROOT/src" ]]; then
  for ext in "${exts[@]}"; do
    count=$(find "$ROOT/src" -name "*.${ext}" -type f 2>/dev/null | wc -l | tr -d ' ')
    source_count=$((source_count + count))
  done
fi

# Count test files
IFS='|' read -ra test_patterns <<< "$HARNESS_TEST_PATTERN"
for pattern in "${test_patterns[@]}"; do
  # Convert glob to find pattern
  if [[ "$pattern" == "**/"* ]]; then
    find_pattern="${pattern#**/}"
    count=$(find "$ROOT" -name "$find_pattern" -type f -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    test_count=$((test_count + count))
  fi
done

if (( source_count > 0 )); then
  coverage_ratio=$(( (test_count * 100) / source_count ))
  (( coverage_ratio > 100 )) && coverage_ratio=100
else
  coverage_ratio=0
fi
harness_pass "coverage-ratio" "Test coverage ratio: ${test_count}/${source_count} (${coverage_ratio}%)"

# --- 2. Architecture violations ---
harness_info "Counting architecture violations..."
arch_violations=0
if [[ -f "$SCRIPT_DIR/lint-architecture.sh" ]]; then
  arch_output=$("$SCRIPT_DIR/lint-architecture.sh" 2>&1 || true)
  arch_violations=$(echo "$arch_output" | grep -c '\[HARNESS:FAIL\]' || true)
fi
if (( arch_violations == 0 )); then
  harness_pass "arch-clean" "No architecture violations"
else
  harness_warn "arch-violations" "$ROOT" "${arch_violations} architecture violation(s) found" \
    "Run scripts/lint-architecture.sh for details." \
    "docs/LAYERS.md"
fi

# --- 3. Doc freshness ---
harness_info "Checking documentation freshness..."
now=$(date +%s)
stale_docs=0
total_docs=0
if [[ -d "$ROOT/docs" ]]; then
  while IFS= read -r doc; do
    [[ -z "$doc" ]] && continue
    total_docs=$((total_docs + 1))
    if [[ "$(uname)" == "Darwin" ]]; then
      mod_time=$(stat -f %m "$doc")
    else
      mod_time=$(stat -c %Y "$doc")
    fi
    age_days=$(( (now - mod_time) / 86400 ))
    if (( age_days > 30 )); then
      stale_docs=$((stale_docs + 1))
    fi
  done < <(find "$ROOT/docs" -name "*.md" -type f 2>/dev/null)
fi

if (( total_docs > 0 )); then
  doc_freshness=$(( ((total_docs - stale_docs) * 100) / total_docs ))
else
  doc_freshness=0
fi
harness_pass "doc-freshness" "Doc freshness: $((total_docs - stale_docs))/${total_docs} docs updated within 30 days (${doc_freshness}%)"

# --- 4. Compute overall score ---
# Weights: coverage 40%, architecture 30%, docs 30%
arch_score=100
if (( arch_violations > 0 )); then
  arch_score=$(( 100 - (arch_violations * 10) ))
  (( arch_score < 0 )) && arch_score=0
fi

overall=$(( (coverage_ratio * 40 + arch_score * 30 + doc_freshness * 30) / 100 ))
(( overall > 100 )) && overall=100
(( overall < 0 )) && overall=0

# Determine grade
grade="F"
if (( overall >= 90 )); then grade="A"
elif (( overall >= 80 )); then grade="B"
elif (( overall >= 70 )); then grade="C"
elif (( overall >= 60 )); then grade="D"
fi

harness_pass "overall-score" "Overall quality score: ${overall}/100 (${grade})"

# --- 5. Write QUALITY_SCORE.md ---
cat > "$OUTPUT_FILE" << EOF
# Quality Score

**Overall: ${overall}/100 (${grade})**

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Stack: ${HARNESS_STACK}

## Breakdown

| Category | Score | Details |
|----------|-------|---------|
| Test Coverage | ${coverage_ratio}% | ${test_count} test files / ${source_count} source files |
| Architecture | ${arch_score}/100 | ${arch_violations} violation(s) |
| Doc Freshness | ${doc_freshness}% | $((total_docs - stale_docs))/${total_docs} docs updated within 30 days |

## Weights

- Test Coverage: 40%
- Architecture Compliance: 30%
- Documentation Freshness: 30%

## How to Improve

$(if (( coverage_ratio < 80 )); then echo "- **Add more tests.** Coverage is below 80%. Run \`scripts/verify-tests-exist.sh\` to find untested files."; fi)
$(if (( arch_violations > 0 )); then echo "- **Fix architecture violations.** Run \`scripts/lint-architecture.sh\` for details."; fi)
$(if (( doc_freshness < 80 )); then echo "- **Update stale docs.** ${stale_docs} docs are older than 30 days."; fi)
$(if (( overall >= 90 )); then echo "- Great job! Score is 90+. Keep it up."; fi)
EOF

harness_info "Wrote quality score to ${OUTPUT_FILE}"
harness_summary "Quality Score"
