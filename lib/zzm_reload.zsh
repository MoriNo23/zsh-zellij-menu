#!/usr/bin/env zsh
# zzm_reload.zsh — Standalone: outputs tab-separated session list for fzf reload
#
# Format per line: session_name\tformatted_display
# Last line: \t← Volver al menú principal
#
# Usage: zsh /path/to/zzm_reload.zsh
#
# Dependencies: zzm_config.zsh, zzm_parse.zsh (in same directory)

setopt shwordsplit 2>/dev/null || true

ZZM_DIR="${0:A:h}"
source "$ZZM_DIR/zzm_config.zsh" 2>/dev/null || true
source "$ZZM_DIR/zzm_parse.zsh" 2>/dev/null || true

sessions=$(zellij list-sessions --no-formatting 2>/dev/null)

if [[ -n "$sessions" ]]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        _zzm_parse_line "$line" || continue
        printf '%s\t%s\n' "$_zzm_name" "$(_zzm_format_display)"
    done <<< "$sessions"
fi

printf '\t%s\n' "${ZZM_ICON_BACK:-← Volver al menú principal}"
