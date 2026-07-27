#!/usr/bin/env bash
# uninstall.sh — Remove zsh-zellij-menu

set -euo pipefail

PLUGIN_DIR="${HOME}/.zsh-zellij-menu"
ZSHRC="${HOME}/.zshrc"

# Backup before modifying
if [[ -f "$ZSHRC" ]]; then
    cp "$ZSHRC" "$ZSHRC.bak"
    echo "💾 Backup creado: $ZSHRC.bak"
fi

# ─── Remove plugin dir ──────────────────────────────────────────────────────
if [[ -d "$PLUGIN_DIR" ]]; then
    rm -rf "$PLUGIN_DIR"
    echo "✅ Removed $PLUGIN_DIR"
else
    echo "ℹ️  $PLUGIN_DIR not found — skipping."
fi

# ─── Remove from .zshrc ─────────────────────────────────────────────────────
MARKER="# zsh-zellij-menu"
END_MARKER="# end zsh-zellij-menu"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    # Remove the block between opening marker and closing marker
    sed -i "/^${MARKER}$/,/^${END_MARKER}$/d" "$ZSHRC"
    echo "✅ Removed from $ZSHRC"
else
    echo "ℹ️  Not found in .zshrc — skipping."
fi

echo ""
echo "🧹 Uninstalled. Restart your terminal."
