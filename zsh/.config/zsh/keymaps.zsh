bindkey '^[f' atuin-search

zle -N mz_insert_path
# alt+o (remapped as cmd+o in ghostty config)
bindkey '^[o' mz_insert_path
zle -N mz_insert_path_home
# NOTE: keybinding having shift is handled by remapping stuff in ghostty config

# ctrl+shift+o
bindkey '\e[1;6O' mz_insert_path_home
bindkey '^Y' autosuggest-accept
# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

fzf-tab-complete() {
  zle expand-or-complete
}
zle -N fzf-tab-complete
bindkey '\e[Z' fzf-tab-complete # Shift+Tab
bindkey '\e '  fzf-tab-complete # Alt+Space (Alt is mapped from Cmd in ghostty)