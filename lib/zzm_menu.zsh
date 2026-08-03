# zzm_menu.zsh — Main TUI logic for zsh-zellij-menu
#
# Provides: zzm_menu() — 2-level interactive Zellij session manager
#
# Level 1 (Main):     ✨ New Session | 📋 Explore Sessions | 🖥️ Shell without Zellij
# Level 2 (Explore):  <session name> ⏱ <time> 📌 <status> | ← Back
#
# Requirements: zsh, fzf, zellij

# Source dependencies
_zzm_dir="${${(%):-%x}:h}"
[[ -f "$_zzm_dir/zzm_config.zsh" ]] && source "$_zzm_dir/zzm_config.zsh"
[[ -f "$_zzm_dir/zzm_parse.zsh" ]] && source "$_zzm_dir/zzm_parse.zsh"

# ─── Warp detection (env vars → process tree walk) ───────────────────────
_zzm_is_warp() {
    [[ "$ZZM_WARP_DETECTION" -eq 0 ]] && return 1

    # Layer 0 (NEW): unequivocal non-Warp signals FIRST.
    # Kitty sets TERM=xterm-kitty but does NOT reset TERM_PROGRAM — so a shell
    # launched under/from Warp can inherit TERM_PROGRAM=WarpTerminal and be
    # falsely detected. TERM is terminal-controlled and reliable, so if the
    # current terminal is unmistakably NOT Warp, bail out early.
    case "$TERM" in
        xterm-kitty|screen|tmux*) return 1 ;;
    esac

    # Layer 1: env vars (no fork). Prefer a Warp-EXCLUSIVE marker over the
    # leaky generic TERM_PROGRAM.
    [[ -n "$WARP_SESSION_ID" ]] && return 0
    [[ -n "$WARP_TERMINAL_SESSION_UUID" ]] && return 0

    # Layer 1b: TERM_PROGRAM only as weak signal, and only when combined with
    # a process-tree confirmation (avoids the leaky false positive).
    setopt local_options extended_glob
    if [[ "$TERM_PROGRAM" == (#i)*warp* ]]; then
        local pp_comm=$(ps -o comm= -p "$PPID" 2>/dev/null)
        [[ "$pp_comm" == "warp" || "$pp_comm" == "warp-terminal" ]] && return 0
    fi

    # Layer 2: parent process check
    local comm=$(ps -o comm= -p "$PPID" 2>/dev/null)
    [[ "$comm" == "warp" || "$comm" == "warp-terminal" ]] && return 0

    return 1
}

# ─── AI agent / tool shell detection ─────────────────────────────────────
# Problem: agent runtimes (opencode, codex, claude, hermes, ...) open their
# own interactive shells with a PTY. They pass `[[ -z "$ZELLIJ" && -t 0 ]]`
# and would block forever on the fzf menu — no human to pick an option.
#
# Layers (same pattern as Warp detection):
#   Layer 1: manual opt-out env var (ZZM_AGENT_SKIP=1) — also for unknown agents
#   Layer 2: env vars set by known agent runtimes
#   Layer 3: ancestor process walk looking for agent binaries
_zzm_is_agent_shell() {
    # Layer 1: manual opt-out (force skip the menu)
    [[ -n "$ZZM_AGENT_SKIP" && "$ZZM_AGENT_SKIP" != "0" ]] && return 0
    [[ "$ZZM_AGENT_DETECTION" -eq 0 ]] && return 1

    # Layer 0 (NEW): direct parent is a real terminal emulator → human shell.
    # Agents open a PTY, they never spawn an emulator; a human shell's parent
    # is ALWAYS the emulator. Cut detection here — this also discards agent env
    # vars (HERMES_SESSION/OPENCODE/CLAUDE_CODE) that leak into the shell via
    # terminal inheritance when kitty/konsole is opened from an agent context.
    local parent_comm
    parent_comm=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d '[:space:]')
    local term_bin
    for term_bin in $ZZM_TERMINAL_BINS; do
        [[ "$parent_comm" == "$term_bin" ]] && return 1
    done

    # Layer 2: env vars set by known agent runtimes
    [[ -n "$HERMES_SESSION" ]] && return 0
    [[ -n "$OPENCODE" ]] && return 0
    [[ -n "$CLAUDE_CODE" ]] && return 0

    # Layer 3: ancestor walk (max 10 levels) for agent binaries
    local pid=$PPID depth=0 comm bin
    while [[ $pid -gt 1 && $depth -lt 10 ]]; do
        comm=$(ps -o comm= -p "$pid" 2>/dev/null | tr -d '[:space:]')
        [[ -z "$comm" ]] && break
        for bin in $ZZM_AGENT_BINS; do
            [[ "$comm" == "$bin" ]] && return 0
        done
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
        (( depth++ ))
    done
    return 1
}

# ─── fzf wrapper ──────────────────────────────────────────────────────────
_zzm_fzf() {
    local header="$1"; shift
    fzf \
        --prompt="zellij ❯ " \
        --header="$header" \
        --header-first \
        --height="${ZZM_FZF_HEIGHT}" \
        --reverse \
        --border="$ZZM_FZF_BORDER" \
        --color="$ZZM_FZF_COLORS" \
        "$@" \
        2>/dev/null
}

# ─── Level 2: Session explorer ───────────────────────────────────────────────
_zzm_explore_sessions() {
    # Path to standalone reload script
    local reload_script="$_zzm_dir/zzm_reload.zsh"

    # Reload command for fzf
    local reload_cmd="zsh $reload_script"

    # Load initial sessions
    local fzf_input
    fzf_input=$(zsh "$reload_script" 2>/dev/null)
    [[ -z "$fzf_input" ]] && return 0

    local selection
    selection=$(printf '%s\n' "$fzf_input" | _zzm_fzf "Sesiones disponibles" \
        --with-nth 2.. \
        --delimiter $'\t' \
        --bind "ctrl-d:execute-silent(zellij kill-session '{1}' 2>/dev/null)+reload($reload_cmd)")

    # Cancel (Ctrl+C/Esc) → back
    [[ -z "$selection" ]] && return 0

    # Back option
    local back_full="${ZZM_ICON_BACK}"
    [[ "$selection" == *"$back_full"* ]] && return 0

    # Extract session name (first tab-separated field)
    local session_name="${selection%%$'\t'*}"

    if [[ -n "$session_name" ]]; then
        zellij attach "$session_name" || {
            print -P "%F{red}${ZZM_MSG_ATTACH_FAIL}${session_name}%f"
            sleep 1
        }
    fi
}

# ─── Level 1: Main menu ──────────────────────────────────────────────────────
zzm_menu() {
    # Skip if inside Zellij already
    [[ -n "$ZELLIJ" ]] && return 0
    # Skip if no TTY
    [[ ! -t 0 ]] && return 0
    # Skip if Warp terminal
    _zzm_is_warp && return 0
    # Skip if an AI agent / tool opened this shell (no human to pick)
    _zzm_is_agent_shell && return 0

    while true; do
        local main_choices=(
            "$ZZM_ICON_NEW"
            "$ZZM_ICON_EXPLORE"
            "$ZZM_ICON_SHELL"
        )

        local selection
        selection=$(printf '%s\n' "${main_choices[@]}" | _zzm_fzf "Zellij - Menú Principal")

        case "$selection" in
            "")
                # Ctrl+C / Esc → exit to shell
                clear; break
                ;;
            "$ZZM_ICON_NEW")
                echo -n "$ZZM_MSG_NEW_PROMPT"
                local session_name
                read session_name
                if [[ -z "$session_name" ]]; then
                    exec zellij
                else
                    exec zellij -s "$session_name"
                fi
                ;;
            "$ZZM_ICON_SHELL")
                clear; break
                ;;
            "$ZZM_ICON_EXPLORE")
                _zzm_explore_sessions
                # After explore (attach or back), loop shows main menu again
                ;;
        esac
    done
}
