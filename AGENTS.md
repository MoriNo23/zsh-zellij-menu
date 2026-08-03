# AGENTS.md — zsh-zellij-menu

Interactive Zellij session manager for zsh (fzf TUI, 2 levels: main menu → session explorer). Pure zsh + fzf + zellij. No build step, no deps beyond zsh/fzf/zellij/bats (tests).

## Reglas obligatorias para agentes IA

- **NO usar `computer_use` ni capturas de pantalla (vision/screenshots) en NINGÚN caso.** Este proyecto se diagnostica por terminal: env vars, `ps`/`/proc` (árbol de procesos), `pgrep`, scripts. El desktop del usuario (kitty/warp/zellij) es sagrado — no se toca, no se captura, no se observa visualmente.
- Si necesitás saber qué ve una shell real: leé `/proc/<pid>/environ` (tr '\0' '\n') y recorré el PPID chain con `ps -o comm= -o ppid=`. Eso alcanza para todo diagnóstico de detección.
- No modificar nada en `~/.zsh-zellij-menu/` sin confirmar primero con el usuario (es la instalación en producción, sincronizada 1:1 desde `lib/`).

## Dev environment

- Repo: este directorio. Instalación de producción: `~/.zsh-zellij-menu/` (copia de `lib/` + plugin).
- Shell de desarrollo: **zsh**. Nunca probar lógica con `bash -n` (el código usa `(#i)` extended_glob, sintaxis zsh — bash tira error falso).
- Sintaxis: `zsh -n lib/zzm_menu.zsh lib/zzm_config.zsh` (y el resto de `lib/`).

## Build & test

- Tests: `bats tests/test-*.bats` — 3 suites: parse (17), warp (7), agent-detection (8). Total 32.
- Mutation testing: `bash scripts/mutate.sh` — 14 defects inyectados, 0 deben sobrevivir.
- Suite completa local: `bats tests/test-parse.bats tests/test-warp.bats tests/test-agent-detection.bats && bash scripts/mutate.sh --quiet`
- CI (GitHub Actions) corre: syntax check zsh + bats 3 suites + mutation. Ver `.github/workflows/ci.yml`.

## Detección (cómo funciona, para no romperla)

- `_zzm_is_warp()`: Layer 0 = `TERM` inequívocamente no-Warp (`xterm-kitty|screen|tmux*`) → bail; Layer 1 = markers exclusivos Warp (`WARP_SESSION_ID`, `WARP_TERMINAL_SESSION_UUID`); Layer 1b = `TERM_PROGRAM` como señal débil SOLO con confirmación del PPID; Layer 2 = parent process. `TERM_PROGRAM` solo es LEAKY (Warp no lo resetea) — nunca usarlo como señal única.
- `_zzm_is_agent_shell()`: Layer 0 = padre directo es emulador de terminal real (`kitty|konsole|xterm|...` en `ZZM_TERMINAL_BINS`) → shell humana, cortar (también descarta env de agente heredado); Layer 1 = opt-out `ZZM_AGENT_SKIP`; Layer 2 = env de agentes (`HERMES_SESSION`, `OPENCODE`, `CLAUDE_CODE`); Layer 3 = ancestor walk (max 10) contra `ZZM_AGENT_BINS`.
- Orden de llamada en `zzm_menu()`: `$ZELLIJ` → `-t 0` → warp → agent.

## Conventions

- Commits en inglés, prefijo lowercase tipo conventional (`feat:`, `fix:`, `docs:`, `test:`).
- Archivos de lib con guión bajo (`zzm_*.zsh`). Código en inglés; strings de UI en español (es el público).
- Test harness de agent-detection usa `exec -a <name>` para simular el comm del padre (los tests reales de capa 0/3 dependen de eso).

## Pitfalls

- **Kitty NO carga `~/.zshrc` por defecto** — kitty inyecta `ZDOTDIR=/usr/lib/kitty/shell-integration/zsh` cuya `.zshenv` carga `~/.zshenv` pero NUNCA `~/.zshrc`. El guard de arranque (`if [[ -z "$ZELLIJ" && -t 0 ]]; then zzm_menu; fi`) NO debe vivir en `.zshrc` si el usuario usa kitty, o el menú jamás arranca. Vive en `~/.zshenv` (el único arranque que kitty manda) con protección `-o interactive && -t 0`. Síntoma: "el menú no aparece en kitty pero sí en otros terminales" — culpable ZDOTDIR, NO la detección.
- `setopt extended_glob` NO está activo por defecto en zsh — `(#i)*warp*` falla silenciosamente fuera de `setopt local_options extended_glob`.
- El test de warp con `TERM_PROGRAM=WarpTerminal` solo debe dar NOT-WARP si el fix de leak sigue vivo (regresión guardada).
- Al sincronizar a prod: `cp lib/zzm_menu.zsh ~/.zsh-zellij-menu/lib/` + `cp lib/zzm_config.zsh ...` y verificar `diff -r --exclude='*.bak*'`.
- No usar `-t 0` sin `-z "$ZELLIJ"`: dentro de zellij el menú no debe relanzarse.
