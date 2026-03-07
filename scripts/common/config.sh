#!/usr/bin/env bash
# config.sh — Shared configuration reading for harness scripts
# Reads harness.json and provides utility functions.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
#   root=$(harness_root)
#   stack=$(read_config '.stack // "auto"')

set -euo pipefail

# Find the harness/project root by walking up from CWD looking for harness.json
harness_root() {
  local dir="${1:-$(pwd)}"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/harness.json" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  # Fallback: if we're in the harness-framework itself, use git root
  local git_root
  git_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  if [[ -n "$git_root" && -f "$git_root/harness.json" ]]; then
    echo "$git_root"
    return 0
  fi
  echo "ERROR: Could not find harness.json in any parent directory" >&2
  return 1
}

# Read a value from harness.json using jq
# Usage: read_config '.version'
read_config() {
  local query="$1"
  local root
  root="$(harness_root)"
  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not installed. Install it: https://jqlang.github.io/jq/download/" >&2
    return 1
  fi
  jq -r "$query" "$root/harness.json"
}

# Check if a file is a template (contains {{PLACEHOLDER}} tokens)
is_template() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  grep -qE '\{\{[A-Z0-9_]+\}\}' "$file"
}

# List unfilled placeholders in a file
list_placeholders() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  grep -oE '\{\{[A-Z0-9_]+\}\}' "$file" | sort -u
}

# List all harness files from the manifest
# Usage: list_files [filter_type]
#   filter_type: "template", "real", "generated", or omit for all
list_files() {
  local filter="${1:-all}"
  local query
  case "$filter" in
    template)  query='.files[] | select(.type == "template") | .path' ;;
    real)      query='.files[] | select(.type == "real") | .path' ;;
    generated) query='.files[] | select(.type == "generated") | .path' ;;
    all)       query='.files[].path' ;;
    *)         echo "ERROR: Unknown filter type: $filter" >&2; return 1 ;;
  esac
  read_config "$query"
}

# Check if a required tool is available
require_tool() {
  local tool="$1"
  local install_hint="${2:-}"
  if ! command -v "$tool" &>/dev/null; then
    echo "ERROR: Required tool '$tool' is not installed." >&2
    [[ -n "$install_hint" ]] && echo "  Install: $install_hint" >&2
    return 1
  fi
}

# Get the scripts directory
harness_scripts_dir() {
  local root
  root="$(harness_root)"
  echo "$root/scripts"
}

# Source the output library if not already loaded
if [[ -z "${_HARNESS_PASS+x}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/output.sh"
fi
