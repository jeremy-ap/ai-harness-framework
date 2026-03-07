#!/usr/bin/env bash
# output.sh — Agent-readable error formatting library
# All harness enforcement scripts source this file.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/output.sh"
#   harness_fail "check-name" "file.ts:7" "Backward layer import" \
#     "File in 'service' layer imports from 'runtime' layer" \
#     "Layers flow forward only: types -> config -> repo -> service -> runtime -> ui" \
#     "Move the shared logic to the 'service' layer or earlier" \
#     "docs/LAYERS.md#forward-only-rule"

set -euo pipefail

# Detect CI mode from --ci flag or CI environment variable
HARNESS_CI="${HARNESS_CI:-false}"
for arg in "$@"; do
  [[ "$arg" == "--ci" ]] && HARNESS_CI=true
done
if [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
  HARNESS_CI=true
fi

# Counters
_HARNESS_PASS=0
_HARNESS_FAIL=0
_HARNESS_WARN=0

# Colors (disabled in CI or when not a terminal)
if [[ -t 1 && "$HARNESS_CI" != "true" ]]; then
  _RED='\033[0;31m'
  _GREEN='\033[0;32m'
  _YELLOW='\033[0;33m'
  _BLUE='\033[0;34m'
  _BOLD='\033[1m'
  _RESET='\033[0m'
else
  _RED='' _GREEN='' _YELLOW='' _BLUE='' _BOLD='' _RESET=''
fi

# harness_fail <check-name> <file:line> <description> <what> <why> <fix> <ref>
harness_fail() {
  local check="$1" location="$2" desc="$3"
  local what="${4:-}" why="${5:-}" fix="${6:-}" ref="${7:-}"
  ((_HARNESS_FAIL++)) || true

  echo -e "${_RED}${_BOLD}[HARNESS:FAIL]${_RESET} ${_RED}${check}${_RESET} | ${location} | ${desc}"
  [[ -n "$what" ]] && echo "  WHAT: ${what}"
  [[ -n "$why" ]]  && echo "  WHY:  ${why}"
  [[ -n "$fix" ]]  && echo "  FIX:  ${fix}"
  [[ -n "$ref" ]]  && echo "  REF:  ${ref}"
  echo ""

  if [[ "$HARNESS_CI" == "true" ]]; then
    local file line
    file="${location%%:*}"
    line="${location##*:}"
    [[ "$line" == "$file" ]] && line=""
    if [[ -n "$line" ]]; then
      echo "::error file=${file},line=${line}::${check}: ${desc} — ${what}"
    else
      echo "::error file=${file}::${check}: ${desc} — ${what}"
    fi
  fi
}

# harness_pass <check-name> <description>
harness_pass() {
  local check="$1" desc="$2"
  ((_HARNESS_PASS++)) || true
  echo -e "${_GREEN}${_BOLD}[HARNESS:PASS]${_RESET} ${_GREEN}${check}${_RESET} | ${desc}"
}

# harness_warn <check-name> <file:line> <description> <what> <fix> <ref>
harness_warn() {
  local check="$1" location="$2" desc="$3"
  local what="${4:-}" fix="${5:-}" ref="${6:-}"
  ((_HARNESS_WARN++)) || true

  echo -e "${_YELLOW}${_BOLD}[HARNESS:WARN]${_RESET} ${_YELLOW}${check}${_RESET} | ${location} | ${desc}"
  [[ -n "$what" ]] && echo "  WHAT: ${what}"
  [[ -n "$fix" ]] && echo "  FIX:  ${fix}"
  [[ -n "$ref" ]] && echo "  REF:  ${ref}"
  echo ""

  if [[ "$HARNESS_CI" == "true" ]]; then
    local file="${location%%:*}"
    echo "::warning file=${file}::${check}: ${desc}"
  fi
}

# harness_info <message>
harness_info() {
  echo -e "${_BLUE}${_BOLD}[HARNESS]${_RESET} $1"
}

# harness_summary — Print pass/fail/warn counts and return appropriate exit code
harness_summary() {
  local label="${1:-Harness Check}"
  echo ""
  echo -e "${_BOLD}═══ ${label} Summary ═══${_RESET}"
  echo -e "  ${_GREEN}PASS: ${_HARNESS_PASS}${_RESET}  ${_RED}FAIL: ${_HARNESS_FAIL}${_RESET}  ${_YELLOW}WARN: ${_HARNESS_WARN}${_RESET}"
  echo ""

  if [[ $_HARNESS_FAIL -gt 0 ]]; then
    return 1
  fi
  return 0
}

# harness_reset_counters — Reset all counters (useful when running sub-checks)
harness_reset_counters() {
  _HARNESS_PASS=0
  _HARNESS_FAIL=0
  _HARNESS_WARN=0
}

# harness_get_fail_count
harness_get_fail_count() {
  echo "$_HARNESS_FAIL"
}

# harness_get_pass_count
harness_get_pass_count() {
  echo "$_HARNESS_PASS"
}

# harness_get_warn_count
harness_get_warn_count() {
  echo "$_HARNESS_WARN"
}
