# zzm_parse.zsh — Parser for `zellij list-sessions --no-formatting` output
#
# Input format (one line per session):
#   web-app [Created 6m 33s ago]
#   api-service [Created 6m 21s ago]
#
# Output: sets global vars _zzm_name, _zzm_time, _zzm_status
#
# Usage:
#   _zzm_parse_line "web-app [Created 6m 33s ago] (EXITED - attach to resurrect)"
#   echo "$_zzm_name"   # web-app
#   echo "$_zzm_time"   # 2h ago
#   echo "$_zzm_status" # EXITED

_zzm_parse_line() {
    local line="$1"
    [[ -z "$line" ]] && return 1

    # Name: everything before " [Created"
    _zzm_name="${line% \[Created*}"

    # After "[Created ": "2h 5m 52s ago] (EXITED - attach to resurrect)"
    local after_time="${line#*\[Created }"

    # Time span: everything before "]"
    _zzm_time="${after_time%%\]*}"

    # Status: between "(" and ")", then strip " - ..." suffix
    _zzm_status=""
    if [[ "$after_time" == *\)* ]]; then
        _zzm_status="${after_time#*\(}"
        _zzm_status="${_zzm_status%\)}"
        _zzm_status="${_zzm_status%% -*}"  # "EXITED" only, not "EXITED - attach to resurrect"
    fi

    return 0
}

# Build a display string from parsed values
# Output: "web-app    ⏱ 6m 33s ago    📌 EXITED"
_zzm_format_display() {
    local display="$_zzm_name    ${ZZM_ICON_TIME} $_zzm_time"
    [[ -n "$_zzm_status" ]] && display+="    ${ZZM_ICON_STATUS} $_zzm_status"
    echo "$display"
}
