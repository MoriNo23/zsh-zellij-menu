# zzm_config.zsh — Configuration defaults for zsh-zellij-menu
# Override any of these by setting them BEFORE calling zzm_menu.

# Icons (customizable)
ZZM_ICON_NEW="✨ Nueva sesión"
ZZM_ICON_EXPLORE="📋 Explorar sesiones"
ZZM_ICON_SHELL="🖥️  Shell sin Zellij"
ZZM_ICON_BACK="← Volver al menú principal"
ZZM_ICON_TIME="⏱"
ZZM_ICON_STATUS="📌"

# fzf styling
ZZM_FZF_HEIGHT="40%"
ZZM_FZF_BORDER="rounded"
ZZM_FZF_COLORS="border:cyan,header:cyan,prompt:green,pointer:green,marker:green"

# Warp detection: set to 0 to disable (always load Zellij menu)
ZZM_WARP_DETECTION=1

# Agent/tool shell detection: set to 0 to disable (menu shows even for agent shells)
ZZM_AGENT_DETECTION=1

# Agent binaries to match in the ancestor process walk. Includes common
# AI coding runtimes (opencode, codex, claude, hermes, gemini, ...).
# node/python appear here too — a real user terminal was never launched by them.
ZZM_AGENT_BINS=(
    hermes opencode codex claude gemini
    node python python3 bun deno npm
)

# Real terminal emulators. A human shell's DIRECT parent is always one of
# these; agent runtimes open a PTY and never spawn an emulator. If the parent
# matches, the shell is human — stop detection immediately (this also discards
# agent env vars inherited through the terminal, e.g. opening kitty from a
# shell where an agent had run).
ZZM_TERMINAL_BINS=(
    kitty kitten konsole xterm urxvt rxvt
    gnome-terminal gnome-terminal-server alacritty wezterm foot st
    tmux screen
)

# Manual opt-out: ZZM_AGENT_SKIP=1 forces the menu to skip the agent check.
# Set it before sourcing zzm_menu.zsh, or export it in any agent/tool env you want
# to protect (works for agents not in ZZM_AGENT_BINS).
# (empty = detection rules apply)

# Messages
ZZM_MSG_ATTACH_FAIL="❌ No se pudo attachar a "
ZZM_MSG_NEW_PROMPT="Nombre (Enter = auto): "
