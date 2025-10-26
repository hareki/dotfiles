bindkey '^[f' atuin-search

# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

bindkey '^Y' autosuggest-accept

fzf-tab-complete() {
  zle expand-or-complete
}
zle -N fzf-tab-complete
bindkey '\e[Z' fzf-tab-complete # Shift+Tab
bindkey '\e '  fzf-tab-complete # Alt+Space (Alt is mapped from Cmd in ghostty)