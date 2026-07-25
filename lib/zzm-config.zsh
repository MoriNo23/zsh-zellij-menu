# zzm-config.zsh — Configuration defaults for zsh-zellij-menu
# Override any of these by setting them BEFORE calling zzm_menu.

# Icons (customizable)
ZQM_ICON_NEW="✨ Nueva sesión"
ZQM_ICON_EXPLORE="📋 Explorar sesiones"
ZQM_ICON_SHELL="🖥️  Shell sin Zellij"
ZQM_ICON_BACK="← Volver al menú principal"
ZQM_ICON_TIME="⏱"
ZQM_ICON_STATUS="📌"

# fzf styling
ZQM_FZF_HEIGHT="40%"
ZQM_FZF_BORDER="rounded"
ZQM_FZF_COLORS="border:cyan,header:cyan,prompt:green,pointer:green,marker:green"

# Warp detection: set to 0 to disable (always load Zellij menu)
ZQM_WARP_DETECTION=1

# Messages
ZQM_MSG_ATTACH_FAIL="❌ No se pudo attachar a '%s'"
ZQM_MSG_NEW_PROMPT="Nombre (Enter = auto): "
