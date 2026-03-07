#!/usr/bin/env bash
# detect-stack.sh — Auto-detect project language/framework
# Exports: HARNESS_STACK, HARNESS_IMPORT_PATTERN, HARNESS_TEST_RUNNER,
#          HARNESS_TEST_PATTERN, HARNESS_SOURCE_EXTENSIONS
#
# Override auto-detection by setting "stack" in harness.json.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/detect-stack.sh"
#   echo "Detected stack: $HARNESS_STACK"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh" 2>/dev/null || true

_detect_stack() {
  local root="${1:-$(pwd)}"

  # Check for override in harness.json
  if [[ -f "$root/harness.json" ]] && command -v jq &>/dev/null; then
    local override
    override="$(jq -r '.stack // empty' "$root/harness.json" 2>/dev/null || echo "")"
    if [[ -n "$override" ]]; then
      echo "$override"
      return 0
    fi
  fi

  # Auto-detect by marker files
  if [[ -f "$root/package.json" ]]; then
    # Check for TypeScript
    if [[ -f "$root/tsconfig.json" ]]; then
      echo "typescript"
    else
      echo "javascript"
    fi
  elif [[ -f "$root/pyproject.toml" || -f "$root/setup.py" || -f "$root/requirements.txt" ]]; then
    echo "python"
  elif [[ -f "$root/go.mod" ]]; then
    echo "go"
  elif [[ -f "$root/Cargo.toml" ]]; then
    echo "rust"
  elif [[ -f "$root/pom.xml" || -f "$root/build.gradle" || -f "$root/build.gradle.kts" ]]; then
    echo "java"
  elif [[ -f "$root/mix.exs" ]]; then
    echo "elixir"
  elif [[ -f "$root/Gemfile" ]]; then
    echo "ruby"
  elif [[ -f "$root/Package.swift" ]]; then
    echo "swift"
  elif [[ -f "$root/*.csproj" || -f "$root/*.sln" ]]; then
    echo "dotnet"
  else
    echo "unknown"
  fi
}

_set_stack_defaults() {
  local stack="$1"

  case "$stack" in
    typescript)
      HARNESS_IMPORT_PATTERN='(import\s+.*from\s+['"'"'"]|require\s*\(['"'"'"])'
      HARNESS_TEST_RUNNER="npm test"
      HARNESS_TEST_PATTERN="**/*.test.ts|**/*.spec.ts|**/*.test.tsx|**/*.spec.tsx"
      HARNESS_SOURCE_EXTENSIONS="ts,tsx"
      ;;
    javascript)
      HARNESS_IMPORT_PATTERN='(import\s+.*from\s+['"'"'"]|require\s*\(['"'"'"])'
      HARNESS_TEST_RUNNER="npm test"
      HARNESS_TEST_PATTERN="**/*.test.js|**/*.spec.js|**/*.test.jsx|**/*.spec.jsx"
      HARNESS_SOURCE_EXTENSIONS="js,jsx"
      ;;
    python)
      HARNESS_IMPORT_PATTERN='(from\s+\S+\s+import|^import\s+)'
      HARNESS_TEST_RUNNER="pytest"
      HARNESS_TEST_PATTERN="**/test_*.py|**/*_test.py"
      HARNESS_SOURCE_EXTENSIONS="py"
      ;;
    go)
      HARNESS_IMPORT_PATTERN='"[^"]+/[^"]+"'
      HARNESS_TEST_RUNNER="go test ./..."
      HARNESS_TEST_PATTERN="**/*_test.go"
      HARNESS_SOURCE_EXTENSIONS="go"
      ;;
    rust)
      HARNESS_IMPORT_PATTERN='(use\s+|mod\s+)'
      HARNESS_TEST_RUNNER="cargo test"
      HARNESS_TEST_PATTERN="**/tests/**/*.rs|**/*_test.rs"
      HARNESS_SOURCE_EXTENSIONS="rs"
      ;;
    java)
      HARNESS_IMPORT_PATTERN='import\s+[\w.]+;'
      HARNESS_TEST_RUNNER="./gradlew test"
      HARNESS_TEST_PATTERN="**/src/test/**/*.java|**/*Test.java"
      HARNESS_SOURCE_EXTENSIONS="java"
      ;;
    elixir)
      HARNESS_IMPORT_PATTERN='(import\s+|alias\s+|use\s+)'
      HARNESS_TEST_RUNNER="mix test"
      HARNESS_TEST_PATTERN="**/test/**/*_test.exs"
      HARNESS_SOURCE_EXTENSIONS="ex,exs"
      ;;
    ruby)
      HARNESS_IMPORT_PATTERN="require[_relative]*\s+['\"]"
      HARNESS_TEST_RUNNER="bundle exec rspec"
      HARNESS_TEST_PATTERN="**/spec/**/*_spec.rb|**/test/**/*_test.rb"
      HARNESS_SOURCE_EXTENSIONS="rb"
      ;;
    *)
      HARNESS_IMPORT_PATTERN='(import|require|use|from)\s+'
      HARNESS_TEST_RUNNER="echo 'No test runner detected'"
      HARNESS_TEST_PATTERN="**/*.test.*|**/*.spec.*|**/test_*.*"
      HARNESS_SOURCE_EXTENSIONS="*"
      ;;
  esac
}

# Run detection
HARNESS_STACK="$(_detect_stack "${1:-$(pwd)}")"
_set_stack_defaults "$HARNESS_STACK"

export HARNESS_STACK
export HARNESS_IMPORT_PATTERN
export HARNESS_TEST_RUNNER
export HARNESS_TEST_PATTERN
export HARNESS_SOURCE_EXTENSIONS
