# zsh-zellij-menu.plugin.zsh
# Entry point — source this from .zshrc or let install.sh handle it.

# Add lib dir to fpath for autoload
local _zzm_plugin_dir="${${(%):-%x}:%/*}/lib"
[[ -d "$_zzm_plugin_dir" ]] && fpath=("$_zzm_plugin_dir" $fpath)

# Autoload the main function
autoload -Uz zzm_menu
