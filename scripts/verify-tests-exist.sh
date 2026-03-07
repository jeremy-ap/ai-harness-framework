#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"
source "$SCRIPT_DIR/common/detect-stack.sh"

ROOT="$(harness_root)"

# Determine source files to check
get_source_files() {
  # Try git diff against main/master first
  local base_branch=""
  if git -C "$ROOT" rev-parse --is-inside-work-tree &>/dev/null; then
    for candidate in main master; do
      if git -C "$ROOT" rev-parse --verify "$candidate" &>/dev/null; then
        base_branch="$candidate"
        break
      fi
    done
  fi

  if [[ -n "$base_branch" ]]; then
    git -C "$ROOT" diff --name-only "$base_branch" -- 2>/dev/null | while IFS= read -r f; do
      [[ -f "$ROOT/$f" ]] && echo "$f"
    done
  else
    # No git history — find all source files by extension
    IFS=',' read -ra exts <<< "$HARNESS_SOURCE_EXTENSIONS"
    for ext in "${exts[@]}"; do
      find "$ROOT/src" -name "*.${ext}" -type f 2>/dev/null | sed "s|^$ROOT/||"
    done
  fi
}

# Filter to only source files (not test files themselves)
is_test_file() {
  local file="$1"
  IFS='|' read -ra patterns <<< "$HARNESS_TEST_PATTERN"
  for pattern in "${patterns[@]}"; do
    # Convert glob to a simple check
    local basename
    basename="$(basename "$file")"
    case "$basename" in
      *.test.*|*.spec.*|test_*.*|*_test.*|*Test.*|*_spec.*) return 0 ;;
    esac
  done
  return 1
}

# Find corresponding test file for a source file
find_test_file() {
  local src_file="$1"
  local basename
  basename="$(basename "$src_file")"
  local name_no_ext="${basename%.*}"
  local ext="${basename##*.}"
  local dir
  dir="$(dirname "$src_file")"

  # Common test file patterns to check
  local candidates=(
    "${dir}/${name_no_ext}.test.${ext}"
    "${dir}/${name_no_ext}.spec.${ext}"
    "${dir}/__tests__/${name_no_ext}.test.${ext}"
    "${dir}/__tests__/${name_no_ext}.spec.${ext}"
    "tests/${dir#src/}/${name_no_ext}.test.${ext}"
    "tests/${dir#src/}/${name_no_ext}.spec.${ext}"
    "tests/${dir#src/}/test_${name_no_ext}.${ext}"
    "${dir}/test_${name_no_ext}.${ext}"
    "${dir}/${name_no_ext}_test.${ext}"
    "tests/${dir#src/}/${name_no_ext}_test.${ext}"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -f "$ROOT/$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# Check for assertion keywords in a test file
has_assertions() {
  local test_file="$1"
  grep -qE '(assert|expect|should|toBe|toEqual|assertEqual|assert_eq|assert_equals|refute|it\(|describe\(|test\(|#\[test\])' "$ROOT/$test_file" 2>/dev/null
}

harness_info "Detected stack: ${HARNESS_STACK}"
harness_info "Test pattern: ${HARNESS_TEST_PATTERN}"

checked=0
while IFS= read -r src_file; do
  # Skip non-source files
  [[ -z "$src_file" ]] && continue

  # Only check files with matching source extensions
  file_ext="${src_file##*.}"
  IFS=',' read -ra exts <<< "$HARNESS_SOURCE_EXTENSIONS"
  ext_match=false
  for ext in "${exts[@]}"; do
    [[ "$file_ext" == "$ext" ]] && ext_match=true
  done
  [[ "$ext_match" == false && "$HARNESS_SOURCE_EXTENSIONS" != "*" ]] && continue

  # Skip test files themselves
  is_test_file "$src_file" && continue

  # Skip index/barrel files
  basename="$(basename "$src_file")"
  [[ "$basename" == index.* ]] && continue

  checked=$((checked + 1))

  test_file=""
  if test_file=$(find_test_file "$src_file"); then
    if has_assertions "$test_file"; then
      harness_pass "test-exists" "Test found for ${src_file} -> ${test_file}"
    else
      harness_warn "test-no-assertions" "$ROOT/$test_file" "Test file has no assertions" \
        "Test file '${test_file}' exists but contains no assertion keywords." \
        "Add meaningful assertions (expect, assert, toBe, etc.)." \
        "docs/DESIGN.md#testing"
    fi
  else
    harness_fail "test-missing" "$ROOT/$src_file" "No test file found" \
      "Source file '${src_file}' has no corresponding test file." \
      "All source files should have test coverage." \
      "Create a test file (e.g., ${src_file%.*}.test.${src_file##*.})." \
      "docs/DESIGN.md#testing"
  fi
done < <(get_source_files)

if (( checked == 0 )); then
  harness_info "No source files to check."
fi

harness_summary "Test Existence"
