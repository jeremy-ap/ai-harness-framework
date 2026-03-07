#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"

# Collect results
total_pass=0
total_fail=0
total_warn=0
all_passed=true

# Run a check script and capture results
run_check() {
  local name="$1"
  local script="$2"
  local args="${3:-}"

  echo ""
  echo -e "${_BLUE}${_BOLD}━━━ ${name} ━━━${_RESET}"
  echo ""

  if [[ ! -f "$script" ]]; then
    echo -e "${_YELLOW}  Script not found: ${script}${_RESET}"
    total_warn=$((total_warn + 1))
    return
  fi

  if [[ ! -x "$script" ]]; then
    echo -e "${_YELLOW}  Script not executable: ${script}${_RESET}"
    total_warn=$((total_warn + 1))
    return
  fi

  local output exit_code
  # shellcheck disable=SC2086
  output=$("$script" $args 2>&1) && exit_code=0 || exit_code=$?

  echo "$output"

  # Parse pass/fail/warn counts from the summary line
  local p f w
  p=$(echo "$output" | grep -oE 'PASS: [0-9]+' | grep -oE '[0-9]+' | tail -1 || echo "0")
  f=$(echo "$output" | grep -oE 'FAIL: [0-9]+' | grep -oE '[0-9]+' | tail -1 || echo "0")
  w=$(echo "$output" | grep -oE 'WARN: [0-9]+' | grep -oE '[0-9]+' | tail -1 || echo "0")

  total_pass=$((total_pass + ${p:-0}))
  total_fail=$((total_fail + ${f:-0}))
  total_warn=$((total_warn + ${w:-0}))

  if (( exit_code != 0 )); then
    all_passed=false
  fi
}

# Pass --ci through if set
ci_flag=""
[[ "$HARNESS_CI" == "true" ]] && ci_flag="--ci"

echo -e "${_BOLD}${_BLUE}"
echo "  _   _                                   ____             _"
echo " | | | | __ _ _ __ _ __   ___  ___ ___   |  _ \\  ___   ___| |_ ___  _ __"
echo " | |_| |/ _\` | '__| '_ \\ / _ \\/ __/ __|  | | | |/ _ \\ / __| __/ _ \\| '__|"
echo " |  _  | (_| | |  | | | |  __/\\__ \\__ \\  | |_| | (_) | (__| || (_) | |"
echo " |_| |_|\\__,_|_|  |_| |_|\\___||___/___/  |____/ \\___/ \\___|\\__\\___/|_|"
echo ""
echo -e "${_RESET}"

harness_info "Running all harness checks..."

# Run each check
run_check "Agent Config"           "$SCRIPT_DIR/lint-agent-config.sh"     "$ci_flag"
run_check "Architecture"           "$SCRIPT_DIR/lint-architecture.sh"     "$ci_flag"
run_check "Boundary Validation"  "$SCRIPT_DIR/lint-boundary-validation.sh"  "$ci_flag"
run_check "Documentation"          "$SCRIPT_DIR/lint-docs.sh"             "$ci_flag"
run_check "Test Existence"         "$SCRIPT_DIR/verify-tests-exist.sh"    "$ci_flag"
run_check "Exec Plans"             "$SCRIPT_DIR/lint-exec-plans.sh"       "$ci_flag"
run_check "Commit Messages"        "$SCRIPT_DIR/lint-commit-messages.sh"  "$ci_flag"

# --- Unified summary ---
echo ""
echo -e "${_BOLD}${_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_RESET}"
echo -e "${_BOLD}         Harness Doctor Summary${_RESET}"
echo -e "${_BOLD}${_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_RESET}"
echo ""
echo -e "  ${_GREEN}PASS: ${total_pass}${_RESET}  ${_RED}FAIL: ${total_fail}${_RESET}  ${_YELLOW}WARN: ${total_warn}${_RESET}"
echo ""

if (( total_fail > 0 )); then
  echo -e "${_RED}${_BOLD}  Some checks failed. Fix the issues above.${_RESET}"
  echo ""
  exit 1
else
  if (( total_warn > 0 )); then
    echo -e "${_YELLOW}${_BOLD}  All checks passed with warnings.${_RESET}"
  else
    echo -e "${_GREEN}${_BOLD}  All checks passed!${_RESET}"
  fi
  echo ""
  exit 0
fi
