#!/usr/bin/env bats
# tests/test-parse.bats — Unit tests for zzm_parse.zsh
#
# The lib dir is overridable via $ZZM_LIB_DIR so the mutation-testing harness
# can point these tests at a mutated copy of the source (see scripts/mutate.sh).

load_lib() {
    local lib_dir="${ZZM_LIB_DIR:-${BATS_TEST_FILENAME%/*}/../lib}"
    source "$lib_dir/zzm_config.zsh"
    source "$lib_dir/zzm_parse.zsh"
}

setup() {
    load_lib
}

# ─── Lifecycle / return codes ─────────────────────────────────────────────

@test "empty line returns error (non-zero)" {
    ! _zzm_parse_line ""
    [[ -z "$_zzm_name" ]]
}

@test "whitespace-only line is tolerated (no crash, empty-ish name)" {
    _zzm_parse_line "   "
    # rc=0: parser is lenient; name collapses to the whitespace (no [Created marker)
    [[ -z "$(printf '%s' "$_zzm_name" | tr -d ' ')" ]]
}

@test "unparseable line (no [Created) tolerated, name preserved" {
    _zzm_parse_line "mystery-format-line"
    [[ "$_zzm_name" == "mystery-format-line" ]]
    # No ']' present => time falls back to the full line (lenient, no crash)
    [[ "$_zzm_time" == "mystery-format-line" ]]
}

# ─── Basic name + time parsing ────────────────────────────────────────────

@test "single-word name, seconds time" {
    _zzm_parse_line "xd [Created 10s ago]"
    [[ "$_zzm_name" == "xd" ]]
    [[ "$_zzm_time" == "10s ago" ]]
    [[ -z "$_zzm_status" ]]
}

@test "multi-word name, composite time" {
    _zzm_parse_line "web-app [Created 6m 33s ago]"
    [[ "$_zzm_name" == "web-app" ]]
    [[ "$_zzm_time" == "6m 33s ago" ]]
}

@test "multi-word name with spaces, day+hour time" {
    _zzm_parse_line "test session [Created 1d 3h ago]"
    [[ "$_zzm_name" == "test session" ]]
    [[ "$_zzm_time" == "1d 3h ago" ]]
}

@test "time with minutes only" {
    _zzm_parse_line "one [Created 9m ago]"
    [[ "$_zzm_time" == "9m ago" ]]
}

@test "time with hours only" {
    _zzm_parse_line "one [Created 5h ago]"
    [[ "$_zzm_time" == "5h ago" ]]
}

# ─── Status parsing ───────────────────────────────────────────────────────

@test "EXITED status, spaces in name, suffix stripped" {
    _zzm_parse_line "ui2 waydroid [Created 2h 5m 52s ago] (EXITED - attach to resurrect)"
    [[ "$_zzm_name" == "ui2 waydroid" ]]
    [[ "$_zzm_time" == "2h 5m 52s ago" ]]
    [[ "$_zzm_status" == "EXITED" ]]
}

@test "status with no dash suffix" {
    _zzm_parse_line "x [Created 1m ago] (ZOMBIE)"
    [[ "$_zzm_status" == "ZOMBIE" ]]
}

@test "no parentheses -> empty status" {
    _zzm_parse_line "clean [Created 3m ago]"
    [[ -z "$_zzm_status" ]]
}

# ─── Hyphens / special chars in name ──────────────────────────────────────

@test "name with hyphen keeps hyphen" {
    _zzm_parse_line "dev-server [Created 4m ago]"
    [[ "$_zzm_name" == "dev-server" ]]
}

@test "name with underscore" {
    _zzm_parse_line "my_session [Created 4m ago]"
    [[ "$_zzm_name" == "my_session" ]]
}

@test "name with dots" {
    _zzm_parse_line "v1.2.3 [Created 4m ago]"
    [[ "$_zzm_name" == "v1.2.3" ]]
}

# ─── format_display ───────────────────────────────────────────────────────

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

# ─── Determinism / idempotence ────────────────────────────────────────────

@test "re-parsing same line is idempotent" {
    _zzm_parse_line "api [Created 1d 2h 3m 4s ago] (EXITED - details)"
    local n1 t1 s1
    n1="$_zzm_name"; t1="$_zzm_time"; s1="$_zzm_status"
    _zzm_parse_line "api [Created 1d 2h 3m 4s ago] (EXITED - details)"
    [[ "$_zzm_name" == "$n1" && "$_zzm_time" == "$t1" && "$_zzm_status" == "$s1" ]]
}