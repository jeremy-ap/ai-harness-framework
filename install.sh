#!/usr/bin/env bash
# install.sh — Bootstrap harness into a target repository
#
# Usage:
#   ./install.sh /path/to/target-repo
#
# Does NOT: install language dependencies, modify existing files, require any runtime beyond bash + jq.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
if [[ -t 1 ]]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
  BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

info()  { echo -e "${BLUE}${BOLD}[harness]${RESET} $1"; }
warn()  { echo -e "${YELLOW}${BOLD}[harness]${RESET} $1"; }
error() { echo -e "${RED}${BOLD}[harness]${RESET} $1"; }
ok()    { echo -e "${GREEN}${BOLD}[harness]${RESET} $1"; }

# Validate arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/target-repo"
  echo ""
  echo "Bootstrap the harness framework into a target git repository."
  echo "Copies all harness files, configures git hooks, and runs health check."
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd || echo "$1")"

# Validate target directory
if [[ ! -d "$TARGET" ]]; then
  error "Target directory does not exist: $TARGET"
  echo ""
  read -rp "Create it? [y/N] " create
  if [[ "$create" =~ ^[Yy]$ ]]; then
    mkdir -p "$TARGET"
    info "Created $TARGET"
  else
    exit 1
  fi
fi

# Validate git repo
if [[ ! -d "$TARGET/.git" ]]; then
  warn "Target is not a git repository: $TARGET"
  read -rp "Initialize git? [y/N] " init_git
  if [[ "$init_git" =~ ^[Yy]$ ]]; then
    git -C "$TARGET" init
    ok "Initialized git repository"
  else
    error "Harness requires a git repository. Aborting."
    exit 1
  fi
fi

# Check for jq
if ! command -v jq &>/dev/null; then
  error "jq is required but not installed."
  echo "  Install: https://jqlang.github.io/jq/download/"
  echo "  macOS:   brew install jq"
  echo "  Ubuntu:  sudo apt-get install jq"
  exit 1
fi

# Read manifest
MANIFEST="$SCRIPT_DIR/harness.json"
if [[ ! -f "$MANIFEST" ]]; then
  error "harness.json manifest not found at $SCRIPT_DIR"
  exit 1
fi

info "Installing harness framework into $TARGET"
echo ""

# Copy files
COPIED=0
SKIPPED=0
TOTAL=$(jq '.files | length' "$MANIFEST")

while IFS= read -r file_path; do
  src="$SCRIPT_DIR/$file_path"
  dst="$TARGET/$file_path"

  # Skip if source doesn't exist (e.g., .gitkeep files)
  if [[ ! -f "$src" ]]; then
    # Create .gitkeep files directly
    if [[ "$file_path" == *".gitkeep" ]]; then
      mkdir -p "$(dirname "$dst")"
      touch "$dst"
      ((COPIED++)) || true
      continue
    fi
    warn "Source not found, skipping: $file_path"
    ((SKIPPED++)) || true
    continue
  fi

  # Skip if target exists
  if [[ -f "$dst" ]]; then
    warn "Already exists, skipping: $file_path"
    ((SKIPPED++)) || true
    continue
  fi

  # Create directory and copy
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  ((COPIED++)) || true
done < <(jq -r '.files[].path' "$MANIFEST")

echo ""
ok "Copied $COPIED files ($SKIPPED skipped)"

# Make scripts executable
if [[ -d "$TARGET/scripts" ]]; then
  find "$TARGET/scripts" -name "*.sh" -exec chmod +x {} \;
  info "Made scripts executable"
fi

# Make git hooks executable
if [[ -d "$TARGET/.githooks" ]]; then
  chmod +x "$TARGET/.githooks"/*
  info "Made git hooks executable"
fi

# Configure git hooks path
git -C "$TARGET" config core.hooksPath .githooks
ok "Configured git hooks path: .githooks"

echo ""

# Run harness-doctor if available
if [[ -x "$TARGET/scripts/harness-doctor.sh" ]]; then
  info "Running initial health check..."
  echo ""
  "$TARGET/scripts/harness-doctor.sh" || true
  echo ""
fi

# Print customization checklist
echo -e "${BOLD}═══ Next Steps ═══${RESET}"
echo ""
echo -e "  If you use Claude Code, run the ${BOLD}/init${RESET} command for guided setup:"
echo -e "    ${BLUE}claude \"/init\"${RESET}"
echo ""
echo "  Otherwise, fill in these files manually:"
echo ""
echo -e "  ${GREEN}1.${RESET} CLAUDE.md             — Fill {{PLACEHOLDER}} tokens for Claude Code"
echo -e "  ${GREEN}2.${RESET} AGENTS.md             — Fill {{PLACEHOLDER}} tokens for Codex/Gemini/Amp"
echo -e "  ${GREEN}3.${RESET} architecture.json     — Define your domains and layer structure"
echo -e "  ${GREEN}4.${RESET} docs/DESIGN.md        — Write your architecture overview"
echo -e "  ${GREEN}5.${RESET} .github/copilot-instructions.md — Customize for GitHub Copilot"
echo -e "  ${GREEN}6.${RESET} .cursor/rules/*.mdc   — Customize for Cursor"
echo ""
echo -e "  Run ${BOLD}./scripts/list-placeholders.sh${RESET} to see all unfilled tokens."
echo -e "  Run ${BOLD}./scripts/harness-doctor.sh${RESET} after customization to verify."
echo ""
ok "Harness framework installed successfully!"
