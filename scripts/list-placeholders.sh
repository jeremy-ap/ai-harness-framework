#!/usr/bin/env bash
# list-placeholders.sh — Scan template files and report unfilled {{PLACEHOLDER}} tokens
#
# Usage:
#   ./scripts/list-placeholders.sh          # Human-readable output
#   ./scripts/list-placeholders.sh --json   # Machine-readable JSON output
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"
JSON_MODE=false

for arg in "$@"; do
  [[ "$arg" == "--json" ]] && JSON_MODE=true
done

# Collect template files from manifest
template_files=()
while IFS= read -r file_path; do
  full_path="$ROOT/$file_path"
  [[ -f "$full_path" ]] && template_files+=("$file_path")
done < <(list_files template)

total_files=0
total_tokens=0

if [[ "$JSON_MODE" == "true" ]]; then
  # JSON output: one object per line
  for file_path in "${template_files[@]}"; do
    full_path="$ROOT/$file_path"
    placeholders=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$full_path" 2>/dev/null | sort -u || true)
    if [[ -z "$placeholders" ]]; then
      continue
    fi
    count=$(echo "$placeholders" | wc -l | tr -d ' ')
    total_files=$((total_files + 1))
    total_tokens=$((total_tokens + count))
    # Build JSON array of placeholder names
    json_arr=$(echo "$placeholders" | sed 's/^/"/;s/$/"/' | paste -sd ',' - | sed 's/^/[/;s/$/]/')
    echo "{\"file\":\"${file_path}\",\"count\":${count},\"placeholders\":${json_arr}}"
  done
  echo "{\"summary\":{\"files\":${total_files},\"tokens\":${total_tokens}}}"
else
  # Human-readable output
  file_details=""
  for file_path in "${template_files[@]}"; do
    full_path="$ROOT/$file_path"
    placeholders=$(grep -oE '\{\{[A-Z0-9_]+\}\}' "$full_path" 2>/dev/null | sort -u || true)
    if [[ -z "$placeholders" ]]; then
      continue
    fi
    count=$(echo "$placeholders" | wc -l | tr -d ' ')
    total_files=$((total_files + 1))
    total_tokens=$((total_tokens + count))
    # Format placeholder list
    placeholder_list=$(echo "$placeholders" | paste -sd ',' - | sed 's/,/, /g')
    file_details+="  ${file_path} (${count} tokens):"$'\n'
    file_details+="    ${placeholder_list}"$'\n'$'\n'
  done

  harness_info "Placeholder scan — ${total_files} files, ${total_tokens} unfilled tokens"
  echo ""
  if [[ -n "$file_details" ]]; then
    echo "$file_details"
  fi
  echo "Summary: ${total_tokens} placeholders across ${total_files} files"
fi
