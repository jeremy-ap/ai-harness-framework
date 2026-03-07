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
  harness_warn "boundary-missing" "$ROOT" "architecture.json not found" \
    "No architecture.json found at project root." \
    "Create architecture.json to enable boundary validation enforcement." \
    "docs/LAYERS.md#boundary-validation-rule"
  harness_summary "Boundary Validation"
  exit 0
fi

require_tool jq "https://jqlang.github.io/jq/download/"

# Check for unfilled placeholders
if is_template "$ARCH_FILE"; then
  placeholders=$(list_placeholders "$ARCH_FILE")
  harness_warn "boundary-template" "$ARCH_FILE" "architecture.json has unfilled placeholders" \
    "Template tokens found: ${placeholders//$'\n'/, }" \
    "Replace {{PLACEHOLDER}} tokens with actual project values." \
    "docs/LAYERS.md#boundary-validation-rule"
  harness_summary "Boundary Validation"
  exit 0
fi

# --- Check if boundary_validation is configured ---
bv_enabled=$(jq -r '.boundary_validation.enabled // false' "$ARCH_FILE")
if [[ "$bv_enabled" != "true" ]]; then
  harness_info "Boundary validation is disabled or not configured in architecture.json."
  harness_summary "Boundary Validation"
  exit 0
fi

harness_pass "boundary-loaded" "boundary_validation enabled in architecture.json"

# --- Read boundary_validation config ---
boundary_layer=$(jq -r '.boundary_validation.boundary_layer // "runtime"' "$ARCH_FILE")
target_layer=$(jq -r '.boundary_validation.target_layer // "service"' "$ARCH_FILE")

# Determine which rules to use based on stack
stack_key="$HARNESS_STACK"
strategy=$(jq -r ".boundary_validation.rules[\"$stack_key\"].strategy // empty" "$ARCH_FILE")
if [[ -z "$strategy" ]]; then
  harness_warn "boundary-no-stack-rules" "$ARCH_FILE" "No boundary validation rules for stack '${stack_key}'" \
    "boundary_validation.rules does not contain an entry for '${stack_key}'." \
    "Add rules for your stack in architecture.json under boundary_validation.rules." \
    "docs/LAYERS.md#boundary-validation-rule"
  harness_summary "Boundary Validation"
  exit 0
fi

harness_info "Stack: ${stack_key}, Strategy: ${strategy}"

# --- Read layer order ---
mapfile -t LAYER_ORDER < <(jq -r '.layers.order[]' "$ARCH_FILE")

# --- Read domain names ---
mapfile -t DOMAINS < <(jq -r '.domains | keys[]' "$ARCH_FILE")

# --- Helper: determine layer from file path (same pattern as lint-architecture.sh) ---
get_file_layer() {
  local filepath="$1"
  local domain="$2"
  local basename
  basename="$(basename "$filepath")"
  local name_no_ext="${basename%%.*}"

  for layer in "${LAYER_ORDER[@]}"; do
    local pattern
    pattern=$(jq -r ".domains[\"$domain\"].layer_structure[\"$layer\"] // empty" "$ARCH_FILE")
    [[ -z "$pattern" ]] && continue

    local pattern_base
    pattern_base="$(basename "${pattern%%\**}")"
    pattern_base="${pattern_base%%.*}"

    if [[ "$name_no_ext" == "$pattern_base" ]]; then
      echo "$layer"
      return 0
    fi

    if [[ "$pattern" == *"/**" ]]; then
      local pattern_dir="${pattern%%/**}"
      if [[ "$filepath" == *"/$pattern_dir/"* || "$filepath" == "$ROOT/$pattern_dir/"* ]]; then
        echo "$layer"
        return 0
      fi
    fi
  done

  echo "unknown"
}

# --- Read stack-specific patterns from architecture.json ---
read_json_array() {
  local jq_path="$1"
  local -n result_arr=$2
  mapfile -t result_arr < <(jq -r "${jq_path}[]? // empty" "$ARCH_FILE" 2>/dev/null)
}

rule_base=".boundary_validation.rules[\"$stack_key\"]"

# Read schema_layer
schema_layer=$(jq -r "${rule_base}.schema_layer // \"types\"" "$ARCH_FILE")

# --- Strategy: runtime_parsing (TypeScript, Python, JavaScript, Ruby) ---
check_runtime_parsing() {
  local src_file="$1"
  local rel_path="$2"

  # Read patterns from config
  local -a validation_imports=()
  local -a parse_patterns=()
  local -a raw_data_patterns=()
  read_json_array "${rule_base}.validation_imports" validation_imports
  read_json_array "${rule_base}.parse_patterns" parse_patterns
  read_json_array "${rule_base}.raw_data_patterns" raw_data_patterns

  # Build grep patterns
  local vi_pattern=""
  for vi in "${validation_imports[@]}"; do
    [[ -z "$vi" ]] && continue
    [[ -n "$vi_pattern" ]] && vi_pattern+="|"
    vi_pattern+="$vi"
  done

  local pp_pattern=""
  for pp in "${parse_patterns[@]}"; do
    [[ -z "$pp" ]] && continue
    [[ -n "$pp_pattern" ]] && pp_pattern+="|"
    pp_pattern+="$pp"
  done

  local rd_pattern=""
  for rd in "${raw_data_patterns[@]}"; do
    [[ -z "$rd" ]] && continue
    [[ -n "$rd_pattern" ]] && rd_pattern+="|"
    rd_pattern+="$rd"
  done

  # Check 1: Validation library imported
  if [[ -n "$vi_pattern" ]]; then
    if ! grep -qE "$vi_pattern" "$src_file" 2>/dev/null; then
      harness_fail "boundary-no-validation-import" "$rel_path" "No validation library imported" \
        "Runtime-layer file has no import matching any known validation library." \
        "External data must be parsed/validated at the boundary layer before reaching service logic." \
        "Import a validation library (e.g., ${validation_imports[0]}) and use it to parse incoming data." \
        "docs/LAYERS.md#boundary-validation-rule"
      return
    fi
  fi

  # Check 2: Parse/validate called
  if [[ -n "$pp_pattern" ]]; then
    if ! grep -qE "$pp_pattern" "$src_file" 2>/dev/null; then
      harness_warn "boundary-no-parse-call" "$rel_path" "Validation library imported but no parse/validate call found" \
        "File imports a validation library but no parse/validate pattern was detected." \
        "Call .parse(), .safeParse(), .validate(), or equivalent on incoming data." \
        "docs/LAYERS.md#boundary-validation-rule"
    fi
  fi

  # Check 3: Raw data passthrough (line-by-line)
  if [[ -n "$rd_pattern" ]]; then
    local line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))

      # Skip comments
      local trimmed="${line#"${line%%[![:space:]]*}"}"
      [[ "$trimmed" == "//"* || "$trimmed" == "#"* || "$trimmed" == "/*"* || "$trimmed" == "*"* ]] && continue

      if echo "$line" | grep -qE "$rd_pattern" 2>/dev/null; then
        # Check if a parse pattern also appears on the same line
        if [[ -n "$pp_pattern" ]] && echo "$line" | grep -qE "$pp_pattern" 2>/dev/null; then
          continue  # parse call wraps the raw data — OK
        fi
        harness_fail "boundary-raw-passthrough" "${rel_path}:${line_num}" "Raw external data passed without validation" \
          "Line contains raw external data access without a parse/validate call on the same line." \
          "External data must be parsed at the boundary (runtime layer) before reaching service logic. Passing raw data risks type mismatches and contract violations." \
          "Parse through a validation schema first, e.g.: schema.parse(req.body) or Model.model_validate(request.json())" \
          "docs/LAYERS.md#boundary-validation-rule"
      fi
    done < "$src_file"
  fi

  # Check 4: Schema layer import
  local schema_pattern=""
  case "$HARNESS_STACK" in
    typescript|javascript) schema_pattern="from.*['\"].*/${schema_layer}['\"]\\|from.*['\"].*/${schema_layer}/\\|from.*['\"]\./${schema_layer}['\"]" ;;
    python)                schema_pattern="from.*${schema_layer}.*import\\|import.*${schema_layer}" ;;
    *)                     schema_pattern="${schema_layer}" ;;
  esac
  if [[ -n "$schema_pattern" ]] && ! grep -qE "$schema_pattern" "$src_file" 2>/dev/null; then
    harness_warn "boundary-no-schema-import" "$rel_path" "No import from schema layer (${schema_layer})" \
      "Runtime file does not import from the '${schema_layer}' layer, suggesting inline validation instead of shared schemas." \
      "Define validation schemas in the ${schema_layer} layer and import them in runtime files." \
      "docs/LAYERS.md#boundary-validation-rule"
  fi
}

# --- Strategy: static_typed (Java, Kotlin) ---
check_static_typed() {
  local src_file="$1"
  local rel_path="$2"

  local -a unsafe_types=()
  local -a framework_patterns=()
  read_json_array "${rule_base}.unsafe_types" unsafe_types
  read_json_array "${rule_base}.framework_patterns" framework_patterns

  # Build unsafe types pattern
  local ut_pattern=""
  for ut in "${unsafe_types[@]}"; do
    [[ -z "$ut" ]] && continue
    [[ -n "$ut_pattern" ]] && ut_pattern+="|"
    ut_pattern+="$ut"
  done

  # Build framework patterns
  local fp_pattern=""
  for fp in "${framework_patterns[@]}"; do
    [[ -z "$fp" ]] && continue
    [[ -n "$fp_pattern" ]] && fp_pattern+="|"
    fp_pattern+="$fp"
  done

  # Check 1: Unsafe types in handlers (line-by-line for location)
  if [[ -n "$ut_pattern" ]]; then
    local line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))

      local trimmed="${line#"${line%%[![:space:]]*}"}"
      [[ "$trimmed" == "//"* || "$trimmed" == "/*"* || "$trimmed" == "*"* ]] && continue

      if echo "$line" | grep -qE "$ut_pattern" 2>/dev/null; then
        harness_fail "boundary-unsafe-type" "${rel_path}:${line_num}" "Unsafe untyped data in handler" \
          "Line uses an untyped or loosely-typed container (e.g., Map<String, Object>, JsonNode, Any)." \
          "Untyped data at the boundary bypasses validation. Use strongly-typed DTOs with validation annotations." \
          "Replace with a typed DTO class annotated with @Valid and field constraints (@NotNull, @Size, etc.)." \
          "docs/LAYERS.md#boundary-validation-rule"
      fi
    done < "$src_file"
  fi

  # Check 2: @RequestBody without @Valid
  if grep -qE '@RequestBody' "$src_file" 2>/dev/null; then
    if [[ -n "$fp_pattern" ]]; then
      if ! grep -qE "$fp_pattern" "$src_file" 2>/dev/null; then
        harness_fail "boundary-missing-valid" "$rel_path" "@RequestBody without @Valid" \
          "File uses @RequestBody but does not pair it with @Valid." \
          "Without @Valid, bean validation annotations on the DTO are not enforced at runtime." \
          "Add @Valid next to @RequestBody: @RequestBody @Valid CreateUserDto dto" \
          "docs/LAYERS.md#boundary-validation-rule"
      fi
    fi
  fi
}

# --- Strategy: explicit_unmarshal (Go, Rust) ---
check_explicit_unmarshal() {
  local src_file="$1"
  local rel_path="$2"

  local -a parse_patterns=()
  local -a unsafe_types=()
  local -a validation_imports=()
  read_json_array "${rule_base}.parse_patterns" parse_patterns
  read_json_array "${rule_base}.unsafe_types" unsafe_types
  read_json_array "${rule_base}.validation_imports" validation_imports

  # Build patterns
  local pp_pattern=""
  for pp in "${parse_patterns[@]}"; do
    [[ -z "$pp" ]] && continue
    [[ -n "$pp_pattern" ]] && pp_pattern+="|"
    pp_pattern+="$pp"
  done

  local ut_pattern=""
  for ut in "${unsafe_types[@]}"; do
    [[ -z "$ut" ]] && continue
    [[ -n "$ut_pattern" ]] && ut_pattern+="|"
    ut_pattern+="$ut"
  done

  local vi_pattern=""
  for vi in "${validation_imports[@]}"; do
    [[ -z "$vi" ]] && continue
    [[ -n "$vi_pattern" ]] && vi_pattern+="|"
    vi_pattern+="$vi"
  done

  # Check 1: Unmarshal present
  if [[ -n "$pp_pattern" ]]; then
    if ! grep -qE "$pp_pattern" "$src_file" 2>/dev/null; then
      harness_warn "boundary-no-unmarshal" "$rel_path" "No unmarshal/decode call found" \
        "Runtime-layer file has no JSON unmarshal or decode pattern." \
        "Ensure incoming data is unmarshaled into typed structs at the boundary." \
        "docs/LAYERS.md#boundary-validation-rule"
    fi
  fi

  # Check 2: Unsafe types (line-by-line)
  if [[ -n "$ut_pattern" ]]; then
    local line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))

      local trimmed="${line#"${line%%[![:space:]]*}"}"
      [[ "$trimmed" == "//"* || "$trimmed" == "/*"* || "$trimmed" == "*"* ]] && continue

      if echo "$line" | grep -qE "$ut_pattern" 2>/dev/null; then
        harness_fail "boundary-unsafe-type" "${rel_path}:${line_num}" "Unsafe untyped data in handler" \
          "Line uses an untyped container (e.g., interface{}, map[string]interface{}, any)." \
          "Untyped data at the boundary bypasses validation. Unmarshal into typed structs." \
          "Define a typed struct and unmarshal into it: json.NewDecoder(r.Body).Decode(&typedReq)" \
          "docs/LAYERS.md#boundary-validation-rule"
      fi
    done < "$src_file"
  fi

  # Check 3: Validation library
  if [[ -n "$vi_pattern" ]]; then
    if ! grep -qE "$vi_pattern" "$src_file" 2>/dev/null; then
      harness_warn "boundary-no-validator" "$rel_path" "No validation library imported" \
        "Runtime-layer file has no import matching a known validation library." \
        "Consider using a validation library (e.g., ${validation_imports[0]}) for struct-level validation." \
        "docs/LAYERS.md#boundary-validation-rule"
    fi
  fi
}

# --- Main enforcement loop ---
for domain in "${DOMAINS[@]}"; do
  domain_path=$(jq -r ".domains[\"$domain\"].path // empty" "$ARCH_FILE")
  if [[ -z "$domain_path" ]]; then
    continue
  fi

  full_domain_path="$ROOT/$domain_path"
  if [[ ! -d "$full_domain_path" ]]; then
    harness_info "Domain directory not found: ${domain_path} (skipping)"
    continue
  fi

  # Find runtime-layer files in this domain
  IFS=',' read -ra exts <<< "$HARNESS_SOURCE_EXTENSIONS"
  while IFS= read -r src_file; do
    [[ -z "$src_file" ]] && continue

    file_layer=$(get_file_layer "$src_file" "$domain")
    if [[ "$file_layer" != "$boundary_layer" ]]; then
      continue  # Only check boundary-layer files
    fi

    rel_path="${src_file#"$ROOT/"}"
    harness_info "Checking boundary file: ${rel_path}"

    case "$strategy" in
      runtime_parsing)    check_runtime_parsing "$src_file" "$rel_path" ;;
      static_typed)       check_static_typed "$src_file" "$rel_path" ;;
      explicit_unmarshal) check_explicit_unmarshal "$src_file" "$rel_path" ;;
      *)
        harness_warn "boundary-unknown-strategy" "$rel_path" "Unknown strategy '${strategy}'" \
          "boundary_validation.rules.${stack_key}.strategy is '${strategy}', which is not recognized." \
          "Use one of: runtime_parsing, static_typed, explicit_unmarshal." \
          "docs/LAYERS.md#boundary-validation-rule"
        ;;
    esac
  done < <(
    for ext in "${exts[@]}"; do
      find "$full_domain_path" -name "*.${ext}" -type f 2>/dev/null
    done
    if [[ "$HARNESS_SOURCE_EXTENSIONS" == "*" ]]; then
      find "$full_domain_path" -type f -not -name "*.md" -not -name "*.json" 2>/dev/null
    fi
  )
done

harness_summary "Boundary Validation"
