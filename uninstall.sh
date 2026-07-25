#!/usr/bin/env bash
# uninstall.sh — Remove zsh-zellij-menu

set -euo pipefail

PLUGIN_DIR="${HOME}/.zsh-zellij-menu"
ZSHRC="${HOME}/.zshrc"

# ─── Remove plugin dir ───────────────────────────────────────────────────────
if [[ -d "$PLUGIN_DIR" ]]; then
    rm -rf "$PLUGIN_DIR"
    echo "✅ Removed $PLUGIN_DIR"
else
    echo "ℹ️  $PLUGIN_DIR not found — skipping."
fi

# ─── Remove from .zshrc ──────────────────────────────────────────────────────
if grep -q "# zsh-zellij-menu" "$ZSHRC" 2>/dev/null; then
    # Remove the block between marker and the ZQM lines
    sed -i '/# zsh-zellij-menu/,/^fi$/d' "$ZSHRC"
    echo "✅ Removed from $ZSHRC"
else
    echo "ℹ️  Not found in .zshrc — skipping."
fi

echo ""
echo "🧹 Uninstalled. Restart your terminal."
