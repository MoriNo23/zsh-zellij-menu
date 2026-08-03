#!/usr/bin/env bash
# scripts/mutate.sh — Mutation testing for the zsh-zellij-menu test suite.
#
# For each mutation (a source-line defect injected into a COPY), it runs the full
# bats suite. If the suite fails → mutation KILLED (tests cover it). If every
# test still passes → mutation SURVIVED → a gap in the tests.
#
# Mutations are applied with literal string replacement via a small python
# helper — far more reliable than sed for zsh syntax with []/()/# specials.
#
# Usage: bash scripts/mutate.sh [--quiet]
# Exit 0 if every mutation is killed; 1 if any survive.

set -u

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

# ─── Mutations: "label|file|OLD_TEXT|NEW_TEXT" (literal, no regex) ──────────
MUTATIONS=(
  # ── Parser (zzm_parse.zsh) ────────────────────────────────────────────────
  "parser-name-first-space|zzm_parse.zsh|_zzm_name=\"\${line% \\[Created*}\"|_zzm_name=\"\${line%% *}\""
  "parser-name-homebrewed|zzm_parse.zsh|_zzm_name=\"\${line% \\[Created*}\"|_zzm_name=\"\$line\""
  "parser-empty-name-loss|zzm_parse.zsh|\${line% \\[Created*}|\${line# \\[Created*}"
  "parser-time-quarter|zzm_parse.zsh|_zzm_time=\"\${after_time%%\\]*}\"|_zzm_time=\"\${after_time%%\\[*}\""
  "parser-time-delete|zzm_parse.zsh|_zzm_time=\"\${after_time%%\\]*}\"|_zzm_time=\"\""
  "parser-status-loose|zzm_parse.zsh|_zzm_status=\"\${_zzm_status%% -*}\"|_zzm_status=\"\${_zzm_status}\""
  "parser-status-never|zzm_parse.zsh|if [[ \"\$after_time\" ==|if [[ \"x\" =="
  "parser-empty-guard|zzm_parse.zsh|[[ -z \"\$line\" ]] && return 1|[[ -n \"\$line\" ]] && return 1"
  # ── Detección Warp (zzm_menu.zsh) ────────────────────────────────────────
  "warp-leaky-tp-regression|zzm_menu.zsh|[[ \"\$pp_comm\" == \"warp\" || \"\$pp_comm\" == \"warp-terminal\" ]] && return 0|return 0"
  "warp-session-id|zzm_menu.zsh|[[ -n \"\$WARP_SESSION_ID\" ]] && return 0|[[ -z \"\$WARP_SESSION_ID\" ]] && return 0"
  # ── Detector agentes (zzm_menu.zsh) ──────────────────────────────────────
  "agent-detection-off-flip|zzm_menu.zsh|[[ \"\$ZZM_AGENT_DETECTION\" -eq 0 ]] && return 1|[[ \"\$ZZM_AGENT_DETECTION\" -eq 0 ]] && return 0"
  "agent-skip-guard|zzm_menu.zsh|[[ -n \"\$ZZM_AGENT_SKIP\" && \"\$ZZM_AGENT_SKIP\" != \"0\" ]] && return 0|[[ -z \"\$ZZM_AGENT_SKIP\" ]] && return 0"
  "agent-opencode-var|zzm_menu.zsh|[[ -n \"\$OPENCODE\" ]] && return 0|[[ -z \"\$OPENCODE\" ]] && return 0"
  "agent-bin-list|zzm_menu.zsh|for bin in \$ZZM_AGENT_BINS; do|for bin in ; do"
)

# python literal-replace helper
apply_literal() {
  local file="$1" old="$2" new="$3"
  python3 - "$file" "$old" "$new" <<'PYEOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(path, encoding="utf-8").read()
if old not in s:
    sys.exit(2)  # marker not found => mutation mis-specified
open(path, "w", encoding="utf-8").write(s.replace(old, new, 1))
PYEOF
}

pass=0
survived=0
declare -a survivors=()

for spec in "${MUTATIONS[@]}"; do
  IFS='|' read -r label file old new <<< "$spec"

  workdir="$(mktemp -d)"
  mkdir -p "$workdir/lib" "$workdir/tests"
  cp "$REPO_DIR"/lib/*.zsh "$workdir/lib/"
  cp "$REPO_DIR"/tests/*.bats "$workdir/tests/"
  cp "$REPO_DIR"/zsh-zellij-menu.plugin.zsh "$workdir/"

  # apply mutation on the COPY
  if ! err=$(apply_literal "$workdir/lib/$file" "$old" "$new" 2>&1); then
    [[ "$QUIET" == 0 ]] && printf "%-18s %-46s [SETUP:\u00a0%s]\n" "mutation" "$label" "$err"
    rm -rf "$workdir"; continue
  fi

  [[ "$QUIET" == 0 ]] && printf "%-18s %-46s " "mutation" "$label"
  if ( cd "$workdir" && bats tests/test-parse.bats tests/test-warp.bats tests/test-agent-detection.bats >/dev/null 2>&1 ); then
    # all passed ON MUTANT → this defect is invisible to the suite
    survived=$((survived+1)); survivors+=("$label")
    [[ "$QUIET" == 0 ]] && echo "SURVIVED"
  else
    pass=$((pass+1))
    [[ "$QUIET" == 0 ]] && echo "killed"
  fi
  rm -rf "$workdir"
done

echo ""
echo "======================================"
echo "mutation-test result"
echo "  killed:   $pass"
echo "  survived: $survived"
if (( survived > 0 )); then
  printf '  survivors: %s\n' "${survivors[*]}"
fi
echo "======================================"
exit $((survived > 0))