# tests/test-warp.bats
# Tests for _zzm_is_warp() — shells out to zsh (zsh-native logic).
# Prints WARP (skip menu) or NOTWARP (launch).
#
# Order matters: zzm_config.zsh sets DEFAULTS on source, so any override from
# the test MUST be applied AFTER sourcing (exactly like production .zshrc).
#
# NOTE (2026-08-03): the detector now treats TERM_PROGRAM as a LEAKY signal.
# A shell can inherit TERM_PROGRAM=WarpTerminal (e.g. Kitty launched under/from
# Warp) without actually being Warp. So TERM_PROGRAM alone must NOT mark WARP —
# it needs a Warp-exclusive marker (WARP_SESSION_ID / WARP_TERMINAL_SESSION_UUID)
# or a confirmed warp/warp-terminal parent process.

setup() {
    REPO_DIR="$BATS_TEST_DIRNAME/.."
}

zzz_warp() {
    # "$1" = env overrides applied AFTER sourcing (so config defaults don't clobber)
    zsh -c "
        _zzm_dir='$REPO_DIR/lib'
        source \"\$_zzm_dir/zzm_config.zsh\"
        source \"\$_zzm_dir/zzm_menu.zsh\"
        unset WARP_SESSION_ID TERM_PROGRAM WARP_TERMINAL_SESSION_UUID
        $1
        if _zzm_is_warp; then echo WARP; else echo NOTWARP; fi
    " "$@"
}

@test "TERM=xterm-kitty (Kitty) is NOTWARP even with leaky TERM_PROGRAM" {
    # Layer 0: TERM is terminal-controlled; a real Kitty shell must never be
    # detected as Warp even if it inherited TERM_PROGRAM=WarpTerminal.
    run zzz_warp "TERM=xterm-kitty; TERM_PROGRAM=WarpTerminal; "
    [[ "$output" == "NOTWARP" ]]
}

@test "TERM=screen (tmux) is NOTWARP" {
    run zzz_warp "TERM=screen; TERM_PROGRAM=WarpTerminal; "
    [[ "$output" == "NOTWARP" ]]
}

@test "WARP_SESSION_ID triggers warp detection" {
    run zzz_warp "WARP_SESSION_ID=abc; "
    [[ "$output" == "WARP" ]]
}

@test "WARP_TERMINAL_SESSION_UUID triggers warp detection" {
    run zzz_warp "WARP_TERMINAL_SESSION_UUID=abc-uuid; "
    [[ "$output" == "WARP" ]]
}

@test "TERM_PROGRAM warp alone (leaky) is NOT-WARP — regression fix" {
    # regression: Kitty/other shells inherit TERM_PROGRAM=WarpTerminal but are
    # NOT Warp. This must NOT hide the menu.
    run zzz_warp "TERM_PROGRAM=WarpTerminal; "
    [[ "$output" == "NOTWARP" ]]
}

@test "warp detection disabled returns NOTWARP" {
    run zzz_warp "ZZM_WARP_DETECTION=0; WARP_SESSION_ID=abc; "
    [[ "$output" == "NOTWARP" ]]
}

@test "clean env is NOTWARP" {
    run zzz_warp ""
    [[ "$output" == "NOTWARP" ]]
}