# zsh-zellij-menu — Interactive Zellij Session Manager for Zsh

[![CI](https://github.com/MoriNo23/zsh-zellij-menu/actions/workflows/ci.yml/badge.svg)](https://github.com/MoriNo23/zsh-zellij-menu/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A 2-level fzf-based TUI for managing Zellij sessions with session name parsing, status display, and Warp terminal detection.

<p align="center">
  <img src="assets/screenshot.svg" alt="zsh-zellij-menu demo" width="720">
</p>

[English](#english) | [Español](#español)

---

## English

### Features

- **2-level TUI**: Main menu → Session explorer with parsed session info
- **Session name parsing**: Correctly handles names with spaces (e.g., `ui2 waydroid`)
- **Status display**: Shows `⏱ time` and `active/EXITED` status for each session
- **Delete sessions**: Press `Ctrl+D` in the session explorer to kill a session (instant, no confirmation)
- **Warp terminal detection**: Auto-skips Zellij menu in Warp Terminal (2-layer detection: env vars + process tree walk)
- **No `exec` on attach**: If attach fails, you return to the menu instead of losing your terminal
- **Configurable**: Override icons, colors, and messages via variables

### Installation

```bash
git clone https://github.com/MoriNo23/zsh-zellij-menu ~/.zsh-zellij-menu
~/.zsh-zellij-menu/install.sh
```

Open a new terminal to activate.

### Manual Installation

```bash
git clone https://github.com/MoriNo23/zsh-zellij-menu ~/.zsh-zellij-menu
```

Add to `.zshrc`:

```zsh
fpath=(~/.zsh-zellij-menu/lib $fpath)
autoload -Uz zzm_menu

# Auto-launch on new terminal (skip in Warp)
if [[ -z "$ZELLIJ" && -t 0 ]]; then zzm_menu; fi
```

### Usage

On a new terminal, the menu appears:

```
✨ Nueva sesión
📋 Explorar sesiones
🖥️  Shell sin Zellij
```

Selecting **📋 Explorar sesiones** shows:

```
web-app         ⏱ 6m ago        ● active
api-service     ⏱ 6m ago        ● active
devops          ⏱ 3m ago        📌 EXITED
← Volver al menú principal
```

### Session Management

Press **`Ctrl+D`** while hovering over a session to kill it instantly. The list reloads automatically.

### Configuration

Override defaults **before** calling `zzm_menu`:

```zsh
ZQM_ICON_NEW="🚀 New Session"
ZQM_ICON_EXPLORE="🔍 Browse Sessions"
ZQM_ICON_SHELL="🐚 Shell"
ZQM_FZF_HEIGHT="50%"
ZQM_FZF_BORDER="double"
ZQM_WARP_DETECTION=0  # disable Warp detection
```

### Requirements

- zsh 5.0+
- fzf
- zellij

### License

MIT — see [LICENSE](LICENSE).

---

## Español 🇪🇸

### Características

- **TUI de 2 niveles**: Menú principal → Explorador de sesiones con información parseada
- **Parseo de nombres**: Maneja correctamente nombres con espacios (ej: `ui2 waydroid`)
- **Estado visual**: Muestra `⏱ tiempo` y estado `active/EXITED` para cada sesión
- **Eliminar sesiones**: Presioná `Ctrl+D` en el explorador para matar una sesión al instante
- **Detección de Warp**: Saltea el menú en Warp Terminal (detección 2 capas: env vars + process tree walk)
- **Sin `exec` en attach**: Si el attach falla, volvés al menú en vez de perder la terminal
- **Configurable**: Personalizá íconos, colores y mensajes

### Instalación

```bash
git clone https://github.com/MoriNo23/zsh-zellij-menu ~/.zsh-zellij-menu
~/.zsh-zellij-menu/install.sh
```

Abrí una terminal nueva para activar.

### Instalación manual

```bash
git clone https://github.com/MoriNo23/zsh-zellij-menu ~/.zsh-zellij-menu
```

Agregar a `.zshrc`:

```zsh
fpath=(~/.zsh-zellij-menu/lib $fpath)
autoload -Uz zzm_menu

# Auto-lanzar en terminal nueva (saltear en Warp)
if [[ -z "$ZELLIJ" && -t 0 ]]; then zzm_menu; fi
```

### Uso

Al abrir una terminal, aparece el menú:

```
✨ Nueva sesión
📋 Explorar sesiones
🖥️  Shell sin Zellij
```

Seleccionando **📋 Explorar sesiones** se muestra:

```
web-app         ⏱ 6m ago        ● active
api-service     ⏱ 6m ago        ● active
devops          ⏱ 3m ago        📌 EXITED
← Volver al menú principal
```

### Gestión de sesiones

Presioná **`Ctrl+D`** sobre una sesión para matarla al instante. La lista se recarga automáticamente.

### Configuración

Podés sobreescribir los defaults **antes** de llamar `zzm_menu`:

```zsh
ZQM_ICON_NEW="🚀 Nueva sesión"
ZQM_ICON_EXPLORE="🔍 Explorar"
ZQM_ICON_SHELL="🐚 Shell"
ZQM_FZF_HEIGHT="50%"
ZQM_FZF_BORDER="double"
ZQM_WARP_DETECTION=0  # desactivar detección de Warp
```

### Requisitos

- zsh 5.0+
- fzf
- zellij

### Licencia

MIT — vea [LICENSE](LICENSE).
