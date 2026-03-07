#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"

ROOT="$(harness_root)"
ARCH_FILE="$ROOT/architecture.json"

if [[ ! -f "$ARCH_FILE" ]]; then
  harness_warn "arch-missing" "$ROOT" "architecture.json not found" \
    "Cannot generate dependency graph without architecture.json." \
    "Create architecture.json first." \
    "docs/LAYERS.md"
  harness_summary "Dependency Graph"
  exit 0
fi

require_tool jq "https://jqlang.github.io/jq/download/"

if is_template "$ARCH_FILE"; then
  harness_warn "arch-template" "$ARCH_FILE" "architecture.json has unfilled placeholders" \
    "Cannot generate graph from a template file." \
    "Replace {{PLACEHOLDER}} tokens with actual values." \
    "docs/LAYERS.md"
  harness_summary "Dependency Graph"
  exit 0
fi

# Read domains and their dependencies
mapfile -t DOMAINS < <(jq -r '.domains | keys[]' "$ARCH_FILE")

if (( ${#DOMAINS[@]} == 0 )); then
  harness_info "No domains defined in architecture.json."
  harness_summary "Dependency Graph"
  exit 0
fi

# --- Mermaid output ---
echo ""
echo "## Mermaid Diagram"
echo ""
echo '```mermaid'
echo "graph LR"

for domain in "${DOMAINS[@]}"; do
  # Sanitize domain name for Mermaid (replace hyphens)
  safe_domain="${domain//-/_}"
  echo "  ${safe_domain}[${domain}]"

  deps=$(jq -r ".domains[\"$domain\"].allowed_domain_dependencies[]?" "$ARCH_FILE" 2>/dev/null)
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    safe_dep="${dep//-/_}"
    echo "  ${safe_domain} --> ${safe_dep}"
  done <<< "$deps"
done

echo '```'
echo ""

harness_pass "mermaid-generated" "Mermaid dependency graph generated"

# --- ASCII output ---
echo "## ASCII Dependency Graph"
echo ""

# Print layer order
mapfile -t LAYER_ORDER < <(jq -r '.layers.order[]' "$ARCH_FILE" 2>/dev/null)
if (( ${#LAYER_ORDER[@]} > 0 )); then
  echo "Layer Order:"
  layer_line=""
  for i in "${!LAYER_ORDER[@]}"; do
    if (( i > 0 )); then
      layer_line+=" -> "
    fi
    layer_line+="${LAYER_ORDER[$i]}"
  done
  echo "  ${layer_line}"
  echo ""
fi

echo "Domain Dependencies:"
echo ""

max_len=0
for domain in "${DOMAINS[@]}"; do
  (( ${#domain} > max_len )) && max_len=${#domain}
done

for domain in "${DOMAINS[@]}"; do
  deps=$(jq -r ".domains[\"$domain\"].allowed_domain_dependencies[]?" "$ARCH_FILE" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
  if [[ -z "$deps" ]]; then
    deps="(none)"
  fi
  printf "  %-${max_len}s  -->  %s\n" "$domain" "$deps"
done

echo ""

harness_pass "ascii-generated" "ASCII dependency graph generated"
harness_summary "Dependency Graph"
