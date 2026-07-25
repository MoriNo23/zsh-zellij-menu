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
    local sessions
    sessions=$(zellij list-sessions --no-formatting 2>/dev/null)

    local session_names=()
    local session_displays=()

    if [[ -n "$sessions" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            _zzm_parse_line "$line" || continue
            session_names+=("$_zzm_name")
            session_displays+=("$_zzm_name    ${ZQM_ICON_TIME} $_zzm_time")
            [[ -n "$_zzm_status" ]] && session_displays[-1]+="    ${ZQM_ICON_STATUS} $_zzm_status"
        done <<< "$sessions"
    fi

    session_displays+=("${ZQM_ICON_BACK}")

    local selection
    selection=$(printf '%s\n' "${session_displays[@]}" | _zzm_fzf "Sesiones disponibles")

    # Back or cancel → return to main menu
    [[ -z "$selection" || "$selection" == "${ZQM_ICON_BACK}" ]] && return 0

    # Find the real session name by index (parallel arrays)
    local idx=0 session_name=""
    for display in "${session_displays[@]}"; do
        ((idx++))
        if [[ "$display" == "$selection" ]]; then
            session_name="${session_names[$idx]}"
            break
        fi
    done

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
