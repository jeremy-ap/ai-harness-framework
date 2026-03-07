#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

VALID_TYPES="feat|fix|docs|style|refactor|test|chore|ci"
LAST_N=""
INPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --last=*)
      LAST_N="${1#--last=}"
      shift
      ;;
    --ci)
      shift  # handled by output.sh
      ;;
    *)
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

validate_message() {
  local msg="$1"
  local source="${2:-stdin}"

  # Get the subject line (first line)
  local subject
  subject="$(echo "$msg" | head -1)"

  # Skip merge commits
  if [[ "$subject" =~ ^Merge ]]; then
    harness_pass "commit-merge" "Merge commit skipped: ${subject:0:50}"
    return
  fi

  # Check conventional commit format: type(scope): description  OR  type: description
  if ! echo "$subject" | grep -qE "^(${VALID_TYPES})(\([a-zA-Z0-9_-]+\))?:\s+.+"; then
    harness_fail "commit-format" "$source" "Invalid conventional commit format" \
      "Subject: '${subject:0:72}'" \
      "Commits must follow: type(scope): description. Valid types: ${VALID_TYPES//|/, }" \
      "Rewrite as: type(scope): lowercase description" \
      "docs/DESIGN.md#commit-conventions"
    return
  fi

  # Check subject line length
  local len=${#subject}
  if (( len > 72 )); then
    harness_fail "commit-length" "$source" "Subject line too long (${len} chars, max 72)" \
      "Subject: '${subject:0:72}...'" \
      "Git tools truncate long subject lines." \
      "Shorten to 72 characters or less." \
      "docs/DESIGN.md#commit-conventions"
  else
    harness_pass "commit-length" "Subject line is ${len} chars"
  fi

  # Check first word of description is lowercase
  local desc
  desc=$(echo "$subject" | sed -E "s/^(${VALID_TYPES})(\([a-zA-Z0-9_-]+\))?:\s+//")
  local first_char="${desc:0:1}"
  if [[ "$first_char" =~ [A-Z] ]]; then
    harness_fail "commit-case" "$source" "Description should start with lowercase" \
      "Description starts with '${first_char}' — '${desc:0:40}'" \
      "Conventional commits use lowercase descriptions." \
      "Change '${first_char}' to '${first_char,,}'." \
      "docs/DESIGN.md#commit-conventions"
  else
    harness_pass "commit-case" "Description starts with lowercase"
  fi

  harness_pass "commit-valid" "Valid: ${subject:0:60}"
}

ROOT="$(harness_root)"

if [[ -n "$LAST_N" ]]; then
  # Validate last N git commits
  harness_info "Checking last ${LAST_N} commit messages..."
  while IFS= read -r commit_hash; do
    [[ -z "$commit_hash" ]] && continue
    msg=$(git -C "$ROOT" log --format=%B -n 1 "$commit_hash")
    validate_message "$msg" "commit:${commit_hash:0:8}"
  done < <(git -C "$ROOT" log --format=%H -n "$LAST_N" 2>/dev/null)
elif [[ -n "$INPUT_FILE" && -f "$INPUT_FILE" ]]; then
  # Validate from file
  harness_info "Checking commit message from file: ${INPUT_FILE}"
  msg=$(cat "$INPUT_FILE")
  validate_message "$msg" "$INPUT_FILE"
elif [[ ! -t 0 ]]; then
  # Read from stdin
  msg=$(cat)
  if [[ -n "$msg" ]]; then
    harness_info "Checking commit message from stdin..."
    validate_message "$msg" "stdin"
  else
    harness_info "No commit message provided on stdin."
  fi
else
  # Default: check last commit
  harness_info "Checking last commit message..."
  if git -C "$ROOT" rev-parse HEAD &>/dev/null; then
    msg=$(git -C "$ROOT" log --format=%B -n 1 HEAD)
    validate_message "$msg" "commit:HEAD"
  else
    harness_info "No git commits found."
  fi
fi

harness_summary "Commit Message Lint"
