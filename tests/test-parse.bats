#!/usr/bin/env bats
# tests/test-parse.bats — Tests for zzm-parse.zsh

# Load the parser
load_lib() {
    local lib_dir="${BATS_TEST_FILENAME%/*}/../lib"
    source "$lib_dir/zzm-config.zsh"
    source "$lib_dir/zzm-parse.zsh"
}

setup() {
    load_lib
}

@test "parse EXITED session with space in name" {
    _zzm_parse_line "ui2 waydroid [Created 2h 5m 52s ago] (EXITED - attach to resurrect)"
    [[ "$_zzm_name" == "ui2 waydroid" ]]
    [[ "$_zzm_time" == "2h 5m 52s ago" ]]
    [[ "$_zzm_status" == "EXITED" ]]
}

@test "parse active session (no status)" {
    _zzm_parse_line "xd [Created 9m 24s ago]"
    [[ "$_zzm_name" == "xd" ]]
    [[ "$_zzm_time" == "9m 24s ago" ]]
    [[ -z "$_zzm_status" ]]
}

@test "parse session with single-word name and EXITED" {
    _zzm_parse_line "waydroid [Created 10s ago] (EXITED - attach to resurrect)"
    [[ "$_zzm_name" == "waydroid" ]]
    [[ "$_zzm_time" == "10s ago" ]]
    [[ "$_zzm_status" == "EXITED" ]]
}

@test "parse session with multi-word name and no status" {
    _zzm_parse_line "test session [Created 1d 3h ago]"
    [[ "$_zzm_name" == "test session" ]]
    [[ "$_zzm_time" == "1d 3h ago" ]]
    [[ -z "$_zzm_status" ]]
}

@test "empty line returns error" {
    _zzm_parse_line ""
    [[ "$?" -ne 0 ]]
}

@test "format_display includes status when present" {
    _zzm_parse_line "ui2 waydroid [Created 2h ago] (EXITED - attach to resurrect)"
    local display
    display=$(_zzm_format_display)
    [[ "$display" == *"ui2 waydroid"* ]]
    [[ "$display" == *"⏱"* ]]
    [[ "$display" == *"2h ago"* ]]
    [[ "$display" == *"📌"* ]]
    [[ "$display" == *"EXITED"* ]]
}

@test "format_display omits status when absent" {
    _zzm_parse_line "xd [Created 9m ago]"
    local display
    display=$(_zzm_format_display)
    [[ "$display" == *"xd"* ]]
    [[ "$display" == *"⏱"* ]]
    [[ "$display" == *"9m ago"* ]]
    ! [[ "$display" == *"📌"* ]]
}
