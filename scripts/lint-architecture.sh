#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/output.sh"
source "$SCRIPT_DIR/common/config.sh"
source "$SCRIPT_DIR/common/detect-stack.sh"

ROOT="$(harness_root)"
ARCH_FILE="$ROOT/architecture.json"

# --- Pre-checks ---
if [[ ! -f "$ARCH_FILE" ]]; then
  harness_warn "arch-missing" "$ROOT" "architecture.json not found" \
    "No architecture.json found at project root." \
    "Create architecture.json to enable layered architecture enforcement." \
    "docs/LAYERS.md"
  harness_summary "Architecture Lint"
  exit 0
fi

require_tool jq "https://jqlang.github.io/jq/download/"

# Check for unfilled placeholders
if is_template "$ARCH_FILE"; then
  placeholders=$(list_placeholders "$ARCH_FILE")
  harness_warn "arch-template" "$ARCH_FILE" "architecture.json has unfilled placeholders" \
    "Template tokens found: ${placeholders//$'\n'/, }" \
    "Replace {{PLACEHOLDER}} tokens with actual project values." \
    "docs/LAYERS.md"
  harness_summary "Architecture Lint"
  exit 0
fi

# --- Parse architecture.json ---
layers_enabled=$(jq -r '.layers.enabled // false' "$ARCH_FILE")
if [[ "$layers_enabled" != "true" ]]; then
  harness_info "Layer enforcement is disabled in architecture.json."
  harness_summary "Architecture Lint"
  exit 0
fi

harness_pass "arch-loaded" "architecture.json loaded, layers enabled"

# Read layer order into array
mapfile -t LAYER_ORDER < <(jq -r '.layers.order[]' "$ARCH_FILE")

# Build layer index map (layer_name -> index)
declare -A LAYER_INDEX
for i in "${!LAYER_ORDER[@]}"; do
  LAYER_INDEX["${LAYER_ORDER[$i]}"]="$i"
done

# Read cross-cutting modules
mapfile -t CROSS_CUTTING < <(jq -r '.layers.providers.cross_cutting_modules[]' "$ARCH_FILE" 2>/dev/null)

# Read domain names
mapfile -t DOMAINS < <(jq -r '.domains | keys[]' "$ARCH_FILE")

# --- Helper: determine layer from file path ---
get_file_layer() {
  local filepath="$1"
  local domain="$2"
  local basename
  basename="$(basename "$filepath")"
  local name_no_ext="${basename%%.*}"

  # Check against layer_structure patterns
  for layer in "${LAYER_ORDER[@]}"; do
    local pattern
    pattern=$(jq -r ".domains[\"$domain\"].layer_structure[\"$layer\"] // empty" "$ARCH_FILE")
    [[ -z "$pattern" ]] && continue

    # Convert glob pattern to a check
    # Pattern like "src/billing/types.*" -> match basename starting with "types"
    local pattern_base
    pattern_base="$(basename "${pattern%%\**}")"
    pattern_base="${pattern_base%%.*}"

    if [[ "$name_no_ext" == "$pattern_base" ]]; then
      echo "$layer"
      return 0
    fi

    # Handle ui/** style patterns (directory match)
    if [[ "$pattern" == *"/**" ]]; then
      local pattern_dir="${pattern%%/**}"
      if [[ "$filepath" == *"/$pattern_dir/"* || "$filepath" == "$ROOT/$pattern_dir/"* ]]; then
        echo "$layer"
        return 0
      fi
    fi
  done

  # Check if it's a providers file
  local providers_pattern
  providers_pattern=$(jq -r ".domains[\"$domain\"].providers // empty" "$ARCH_FILE")
  if [[ -n "$providers_pattern" ]]; then
    local prov_base
    prov_base="$(basename "${providers_pattern%%.*}")"
    if [[ "$name_no_ext" == "$prov_base" ]]; then
      echo "providers"
      return 0
    fi
  fi

  echo "unknown"
}

# --- Helper: check if a file is a providers file ---
is_providers_file() {
  local filepath="$1"
  local basename
  basename="$(basename "$filepath")"
  local name_no_ext="${basename%%.*}"
  [[ "$name_no_ext" == "providers" ]]
}

# --- Helper: resolve import path to domain and internal path ---
resolve_import() {
  local import_path="$1"
  local current_domain="$2"

  # Clean up the import path (remove quotes, semicolons, etc.)
  import_path="${import_path//\'/}"
  import_path="${import_path//\"/}"
  import_path="${import_path//;/}"
  import_path="${import_path%%\"*}"

  # Skip relative imports within same file tree (./foo, ../foo)
  if [[ "$import_path" == "./"* || "$import_path" == "../"* ]]; then
    echo "relative:${import_path}"
    return
  fi

  # Check if it imports from another domain
  for domain in "${DOMAINS[@]}"; do
    [[ "$domain" == "$current_domain" ]] && continue
    local domain_path
    domain_path=$(jq -r ".domains[\"$domain\"].path // empty" "$ARCH_FILE")
    [[ -z "$domain_path" ]] && continue

    if [[ "$import_path" == "$domain"* || "$import_path" == "$domain_path"* ]]; then
      # Check if it's importing from index (public API) or internal
      local after_domain="${import_path#"$domain"}"
      after_domain="${after_domain#/}"
      if [[ -z "$after_domain" || "$after_domain" == "index" || "$after_domain" == "index."* ]]; then
        echo "domain-public:${domain}"
      else
        echo "domain-internal:${domain}:${after_domain}"
      fi
      return
    fi
  done

  # Check if it imports a cross-cutting module
  for module in "${CROSS_CUTTING[@]}"; do
    if [[ "$import_path" == "$module"* || "$import_path" == *"/$module"* || "$import_path" == *"/$module/"* ]]; then
      echo "cross-cutting:${module}"
      return
    fi
  done

  echo "external:${import_path}"
}

# --- Main enforcement loop ---
for domain in "${DOMAINS[@]}"; do
  harness_info "Checking domain: ${domain}"

  domain_path=$(jq -r ".domains[\"$domain\"].path // empty" "$ARCH_FILE")
  if [[ -z "$domain_path" ]]; then
    harness_warn "domain-no-path" "$ARCH_FILE" "Domain '${domain}' has no path defined"
    continue
  fi

  full_domain_path="$ROOT/$domain_path"
  if [[ ! -d "$full_domain_path" ]]; then
    harness_info "Domain directory not found: ${domain_path} (skipping)"
    continue
  fi

  # Find all source files in domain
  IFS=',' read -ra exts <<< "$HARNESS_SOURCE_EXTENSIONS"
  while IFS= read -r src_file; do
    [[ -z "$src_file" ]] && continue

    # Determine this file's layer
    file_layer=$(get_file_layer "$src_file" "$domain")
    if [[ "$file_layer" == "unknown" ]]; then
      continue  # Skip files that don't map to a layer
    fi

    # Get this file's layer index
    file_layer_idx="${LAYER_INDEX[$file_layer]:-}"
    if [[ -z "$file_layer_idx" && "$file_layer" != "providers" ]]; then
      continue
    fi

    rel_path="${src_file#"$ROOT/"}"

    # Scan for import statements
    line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))

      # Extract import path from the line
      import_path=""

      # TypeScript/JavaScript: import ... from 'path' or require('path')
      if [[ "$line" =~ from[[:space:]]+[\'\"]([^\'\"]+)[\'\"] ]]; then
        import_path="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ require\([\'\"]([^\'\"]+)[\'\"]\) ]]; then
        import_path="${BASH_REMATCH[1]}"
      # Python: from X import Y or import X
      elif [[ "$line" =~ ^from[[:space:]]+([^[:space:]]+)[[:space:]]+import ]]; then
        import_path="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^import[[:space:]]+([^[:space:];]+) ]]; then
        import_path="${BASH_REMATCH[1]}"
      # Go: "package/path"
      elif [[ "$line" =~ \"([^\"]+/[^\"]+)\" ]]; then
        import_path="${BASH_REMATCH[1]}"
      fi

      [[ -z "$import_path" ]] && continue

      resolved=$(resolve_import "$import_path" "$domain")
      resolved_type="${resolved%%:*}"
      resolved_detail="${resolved#*:}"

      case "$resolved_type" in
        relative)
          # Check forward-only for relative imports within same domain
          # Determine target layer from import path
          local_target="${resolved_detail##*/}"
          local_target="${local_target%%.*}"

          target_layer=""
          for layer in "${LAYER_ORDER[@]}"; do
            local pat_base
            pat_base=$(jq -r ".domains[\"$domain\"].layer_structure[\"$layer\"] // empty" "$ARCH_FILE")
            [[ -z "$pat_base" ]] && continue
            pat_base="$(basename "${pat_base%%.*}")"
            pat_base="${pat_base%%\**}"
            if [[ "$local_target" == "$pat_base" ]]; then
              target_layer="$layer"
              break
            fi
          done

          if [[ -n "$target_layer" && "$file_layer" != "providers" ]]; then
            target_idx="${LAYER_INDEX[$target_layer]:-}"
            if [[ -n "$target_idx" && -n "$file_layer_idx" && "$target_idx" -gt "$file_layer_idx" ]]; then
              harness_fail "layer-violation" "${rel_path}:${line_num}" "Backward layer import" \
                "File in '${file_layer}' layer imports from '${target_layer}' layer (${import_path})" \
                "Layers flow forward only: $(IFS=' -> '; echo "${LAYER_ORDER[*]}"). '${file_layer}' (index ${file_layer_idx}) cannot import from '${target_layer}' (index ${target_idx})." \
                "Move the shared logic to the '${file_layer}' layer or earlier, or restructure so ${target_layer} calls ${file_layer} (not the reverse)." \
                "docs/LAYERS.md#forward-only-rule"
            fi
          fi
          ;;

        cross-cutting)
          # Providers gate check
          if ! is_providers_file "$src_file"; then
            local module_name="${resolved_detail}"
            harness_fail "providers-violation" "${rel_path}:${line_num}" "Direct cross-cutting import" \
              "File imports '${module_name}' directly instead of via providers." \
              "Cross-cutting concerns (${CROSS_CUTTING[*]}) must enter each domain through its explicit providers interface." \
              "1. Add the ${module_name} capability to ${domain_path}/providers.*  2. Import it from './providers' in this file instead." \
              "docs/LAYERS.md#providers-pattern"
          fi
          ;;

        domain-internal)
          # Cross-domain public API check
          local target_domain="${resolved_detail%%:*}"
          local internal_path="${resolved_detail#*:}"
          harness_fail "cross-domain-boundary" "${rel_path}:${line_num}" "Internal cross-domain import" \
            "Domain '${domain}' imports '${target_domain}/${internal_path}' directly (internal file)." \
            "Cross-domain imports must go through the public API (src/${target_domain}/index.*) to maintain domain encapsulation." \
            "Export the needed interface from src/${target_domain}/index.*, then import from '${target_domain}' or '${target_domain}/index' instead of '${target_domain}/${internal_path}'." \
            "docs/LAYERS.md#cross-domain-rule"
          ;;

        domain-public)
          harness_pass "cross-domain-ok" "${rel_path}:${line_num} imports ${resolved_detail} via public API"
          ;;
      esac
    done < "$src_file"

  done < <(
    for ext in "${exts[@]}"; do
      find "$full_domain_path" -name "*.${ext}" -type f 2>/dev/null
    done
    # Also handle wildcard extensions
    if [[ "$HARNESS_SOURCE_EXTENSIONS" == "*" ]]; then
      find "$full_domain_path" -type f -not -name "*.md" -not -name "*.json" 2>/dev/null
    fi
  )
done

harness_summary "Architecture Lint"
