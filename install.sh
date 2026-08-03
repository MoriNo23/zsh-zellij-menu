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

# ─── Add to .zshrc (function available) ─────────────────────────────────────
MARKER="# zsh-zellij-menu"
END_MARKER="# end zsh-zellij-menu"

if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo "ℹ️  Plugin already in .zshrc — skipping."
else
    {
        echo ""
        echo "$MARKER"
        echo "fpath=(~/.zsh-zellij-menu/lib \$fpath)"
        echo "source ~/.zsh-zellij-menu/lib/zzm_menu.zsh"
        echo "$END_MARKER"
    } >> "$ZSHRC"
    echo "✅ Added lib source to $ZSHRC"
fi

# ─── Add auto-launch guard to .zshenv (NOT .zshrc) ──────────────────────────
# kitty (and other terminals) inject ZDOTDIR and never load ~/.zshrc, so the
# auto-launch guard must live in the one startup file every shell reads.
ZSENV="${HOME}/.zshenv"
if grep -q "ZELLIJ MENU" "$ZSENV" 2>/dev/null; then
    echo "ℹ️  Auto-launch guard already in .zshenv — skipping."
else
    {
        echo ""
        echo "# ============================================================"
        echo "# ZSH ZELLIJ MENU — auto-launch guard (.zshenv, not .zshrc)"
        echo "# Kitty injects ZDOTDIR and never loads ~/.zshrc; .zshenv is"
        echo "# the one startup file every zsh reads. Guarded for interactive"
        echo "# shells only (skips agents, non-TTY, inside Zellij)."
        echo "# ============================================================"
        echo 'if [[ -o interactive && -z "$ZELLIJ" && -t 0 ]]; then'
        echo '    source ~/.zsh-zellij-menu/lib/zzm_menu.zsh'
        echo '    zzm_menu'
        echo 'fi'
    } >> "$ZSENV"
    echo "✅ Added auto-launch guard to $ZSENV"
fi

echo ""
echo "🚀 Done! Open a new terminal to activate zsh-zellij-menu."
