# zzm-menu.zsh — Main TUI logic for zsh-zellij-menu
#
# Provides: zzm_menu() — 2-level interactive Zellij session manager
#
# Level 1 (Main):     ✨ New Session | 📋 Explore Sessions | 🖥️ Shell without Zellij
# Level 2 (Explore):  <session name> ⏱ <time> 📌 <status> | ← Back
#
# Requirements: zsh, fzf, zellij

# Source dependencies
local _zzm_dir="${${(%):-%x}:%/*}"
[[ -f "$_zzm_dir/zzm-config.zsh" ]] && source "$_zzm_dir/zzm-config.zsh"
[[ -f "$_zzm_dir/zzm-parse.zsh" ]] && source "$_zzm_dir/zzm-parse.zsh"

# ─── Warp detection (2-layer: env vars + process tree walk) ────────────────
_zzm_is_warp() {
    [[ "$ZQM_WARP_DETECTION" -eq 0 ]] && return 1

    # Layer 1: env vars (0ms, no fork)
    [[ -n "$WARP_SESSION_ID" ]] && return 0
    [[ "$TERM_PROGRAM" == (#i)*warp* ]] && return 0

    # Layer 2: process tree walk (5-10ms, portable)
    local pid=$$ depth=0
    while [[ $pid -gt 1 && $depth -lt 10 ]]; do
        local comm=$(ps -o comm= -p "$pid" 2>/dev/null)
        [[ "$comm" == "warp-terminal" || "$comm" == "warp" ]] && return 0
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')
        (( depth++ ))
    done
    return 1
}

# ─── fzf wrapper ─────────────────────────────────────────────────────────────
_zzm_fzf() {
    local header="$1"
    fzf \
        --prompt="zellij ❯ " \
        --header="$header" \
        --header-first \
        --height="${ZQM_FZF_HEIGHT}" \
        --reverse \
        --border="$ZQM_FZF_BORDER" \
        --color="$ZQM_FZF_COLORS" \
        2>/dev/null
}

# ─── Level 2: Session explorer ───────────────────────────────────────────────
_zzm_explore_sessions() {
    # Path to standalone reload script
    local reload_script="$_zzm_dir/zzm-reload.zsh"

    # Reload command for fzf
    local reload_cmd="zsh $reload_script"

    # Load initial sessions
    local fzf_input
    fzf_input=$(zsh "$reload_script" 2>/dev/null)

    [[ -z "$fzf_input" ]] && return 0

    local selection
    selection=$(printf '%s\n' "$fzf_input" | fzf \
        --prompt="zellij ❯ " \
        --header="Sesiones disponibles" \
        --header-first \
        --height="${ZQM_FZF_HEIGHT}" \
        --reverse \
        --border="$ZQM_FZF_BORDER" \
        --color="$ZQM_FZF_COLORS" \
        --with-nth 2.. \
        --delimiter $'\t' \
        --bind "ctrl-d:execute-silent(zellij kill-session {1} 2>/dev/null)+reload($reload_cmd)" \
        2>/dev/null)

    # Cancel (Ctrl+C/Esc) → back
    [[ -z "$selection" ]] && return 0

    # Back option
    local back_full="${ZQM_ICON_BACK}"
    [[ "$selection" == *"$back_full"* ]] && return 0

    # Extract session name (first tab-separated field)
    local session_name="${selection%%$'\t'*}"

    if [[ -n "$session_name" ]]; then
        zellij attach "$session_name" || {
            print -P "%F{red}${ZQM_MSG_ATTACH_FAIL}%f" "$session_name"
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

    while true; do
        local main_choices=(
            "$ZQM_ICON_NEW"
            "$ZQM_ICON_EXPLORE"
            "$ZQM_ICON_SHELL"
        )

        local selection
        selection=$(printf '%s\n' "${main_choices[@]}" | _zzm_fzf "Zellij - Menú Principal")

        case "$selection" in
            "")
                # Ctrl+C / Esc → exit to shell
                clear; break
                ;;
            "$ZQM_ICON_NEW")
                echo -n "$ZQM_MSG_NEW_PROMPT"
                local session_name
                read session_name
                [[ -z "$session_name" ]] && exec zellij || exec zellij -s "$session_name"
                ;;
            "$ZQM_ICON_SHELL")
                clear; break
                ;;
            "$ZQM_ICON_EXPLORE")
                _zzm_explore_sessions
                # After explore (attach or back), loop shows main menu again
                ;;
        esac
    done
}
