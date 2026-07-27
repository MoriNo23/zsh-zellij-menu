# zzm-config.zsh — Configuration defaults for zsh-zellij-menu
# Override any of these by setting them BEFORE calling zzm_menu.

# Icons (customizable)
ZZM_ICON_NEW="✨ Nueva sesión"
ZZM_ICON_EXPLORE="📋 Explorar sesiones"
ZZM_ICON_SHELL="🖥️  Shell sin Zellij"
ZZM_ICON_BACK="← Volver al menú principal"
ZZM_ICON_TIME="⏱"
ZZM_ICON_STATUS="📌"

# fzf styling
ZZM_FZF_HEIGHT="40%"
ZZM_FZF_BORDER="rounded"
ZZM_FZF_COLORS="border:cyan,header:cyan,prompt:green,pointer:green,marker:green"

# Warp detection: set to 0 to disable (always load Zellij menu)
ZZM_WARP_DETECTION=1

# Messages
ZZM_MSG_ATTACH_FAIL="❌ No se pudo attachar a "
ZZM_MSG_NEW_PROMPT="Nombre (Enter = auto): "
