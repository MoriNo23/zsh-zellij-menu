#!/usr/bin/env zsh
# zzm-reload.zsh — Standalone: outputs tab-separated session list for fzf reload
#
# Format per line: session_name\tformatted_display
# Last line: \t← Volver al menú principal
#
# Usage: zsh /path/to/zzm-reload.zsh
#
# Dependencies: zzm-config.zsh, zzm-parse.zsh (in same directory)

setopt shwordsplit 2>/dev/null || true

ZZM_DIR="${0:A:h}"
source "$ZZM_DIR/zzm-config.zsh" 2>/dev/null || true
source "$ZZM_DIR/zzm-parse.zsh" 2>/dev/null || true

sessions=$(zellij list-sessions --no-formatting 2>/dev/null)

if [[ -n "$sessions" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        _zzm_parse_line "$line" || continue
        local display="$_zzm_name    ${ZQM_ICON_TIME:-⏱} $_zzm_time"
        [[ -n "$_zzm_status" ]] && display+="    ${ZQM_ICON_STATUS:-📌} $_zzm_status"
        printf '%s\t%s\n' "$_zzm_name" "$display"
    done <<< "$sessions"
fi

printf '\t%s\n' "${ZQM_ICON_BACK:-← Volver al menú principal}"
