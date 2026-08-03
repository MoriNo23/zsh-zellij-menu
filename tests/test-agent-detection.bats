# tests/test-agent-detection.bats
# Tests for _zzm_is_agent_shell() — shells out to zsh since the logic is zsh-native.
#
# Each test runs zsh with the real config + menu sourced and sets the case via
# an env var. `_zzm_is_agent_shell` prints "AGENT" (skip) or "HUMAN" (launch).

setup() {
    REPO_DIR="$BATS_TEST_DIRNAME/.."
}

# helper: run the detection with given env vars, print AGENT or HUMAN
zzz_detect() {
    zsh -c "
        _zzm_dir='$REPO_DIR/lib'
        source \"\$_zzm_dir/zzm_config.zsh\"
        source \"\$_zzm_dir/zzm_menu.zsh\"
        unset ZZM_AGENT_SKIP
        $1  # extra env assignments from the test
        if _zzm_is_agent_shell; then echo AGENT; else echo HUMAN; fi
    " "$@"
}

@test "manual opt-out ZZZM_AGENT_SKIP forces skip" {
    run zzz_detect "ZZM_AGENT_SKIP=1; "
    [[ "$output" == "AGENT" ]]
}

@test "OPENCODE env var triggers skip" {
    run zzz_detect "OPENCODE=1; "
    [[ "$output" == "AGENT" ]]
}

@test "HERMES_SESSION triggers skip" {
    run zzz_detect "HERMES_SESSION=1; "
    [[ "$output" == "AGENT" ]]
}

@test "detection disabled returns HUMAN" {
    run zzz_detect "ZZM_AGENT_DETECTION=0; "
    [[ "$output" == "HUMAN" ]]
}

@test "empty agent-bin list returns HUMAN (deterministic)" {
    run zzz_detect "ZZM_AGENT_BINS=(); "
    [[ "$output" == "HUMAN" ]]
}

@test "ancestor binary opencode triggers skip (Layer 3 process walk)" {
    # Write a probe script once (no nested-quoting), then run it under a bash
    # parent renamed to an agent binary via `exec -a`.
    local probe="$BATS_TEST_TMPDIR/probe.zsh"
    printf '%s\n' \
        "_zzm_dir='$REPO_DIR/lib'" \
        'source "$_zzm_dir/zzm_config.zsh"' \
        'source "$_zzm_dir/zzm_menu.zsh"' \
        'unset ZZM_AGENT_SKIP' \
        'if _zzm_is_agent_shell; then echo AGENT; else echo HUMAN; fi' \
        > "$probe"

    if command -v bash >/dev/null 2>&1; then
        local out
        out=$(bash -c 'exec -a opencode zsh --no-rcs "$1"' _ "$probe" 2>/dev/null)
        [[ "$out" == "AGENT" ]]
    else
        skip "bash not available (exec -a needed to rename parent)"
    fi
}