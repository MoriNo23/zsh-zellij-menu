#!/usr/bin/env bash
# install.sh — Install zsh-zellij-menu
#
# Clones/copies the plugin to ~/.zsh-zellij-menu and adds the source line
# to your .zshrc.

set -euo pipefail

PLUGIN_DIR="${HOME}/.zsh-zellij-menu"
ZSHRC="${HOME}/.zshrc"

# ─── Safety checks ──────────────────────────────────────────────────────────
if [[ -z "${HOME:-}" ]]; then
    echo "❌ \$HOME is empty — aborting."
    exit 1
fi

# Backup .zshrc before modifying
if [[ -f "$ZSHRC" ]]; then
    cp "$ZSHRC" "$ZSHRC.bak"
    echo "💾 Backup creado: $ZSHRC.bak"
fi

# ─── Copy plugin files ──────────────────────────────────────────────────────
if [[ -d "$PLUGIN_DIR" ]]; then
    echo "⚠️  $PLUGIN_DIR already exists. Overwriting..."
    rm -rf "$PLUGIN_DIR"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Copy only runtime files: lib/ + plugin.zsh + completions/
install -d "$PLUGIN_DIR/lib"
cp "$SCRIPT_DIR/zsh-zellij-menu.plugin.zsh" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/lib/"*.zsh "$PLUGIN_DIR/lib/"
[[ -d "$SCRIPT_DIR/completions" ]] && cp -r "$SCRIPT_DIR/completions" "$PLUGIN_DIR/"

echo "✅ Plugin installed to $PLUGIN_DIR"

# ─── Add to .zshrc ──────────────────────────────────────────────────────────
MARKER="# zsh-zellij-menu"
END_MARKER="# end zsh-zellij-menu"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo "ℹ️  Plugin already in .zshrc — skipping."
else
    {
        echo ""
        echo "$MARKER"
        echo "fpath=(~/.zsh-zellij-menu/lib \$fpath)"
        echo "autoload -Uz zzm_menu"
        echo ""
        echo "# Zellij TUI (auto on new terminal, skip in Warp)"
        echo 'if [[ -z "$ZELLIJ" && -t 0 ]]; then zzm_menu; fi'
        echo "$END_MARKER"
    } >> "$ZSHRC"
    echo "✅ Added to $ZSHRC"
fi

echo ""
echo "🚀 Done! Open a new terminal to activate zsh-zellij-menu."
