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

    # Layer 1: env vars (no fork)
    [[ -n "$WARP_SESSION_ID" ]] && return 0
    [[ "$TERM_PROGRAM" == (#i)*warp* ]] && return 0

    # Layer 2: check parent process (solo $PPID, no tree walk)
    local comm=$(ps -o comm= -p "$PPID" 2>/dev/null)
    [[ "$comm" == "warp" || "$comm" == "warp-terminal" ]] && return 0

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
