zle -N load_fzf_completion
bindkey '^R' load_fzf_completion

zle -N mz_insert_path
bindkey '^O' mz_insert_path

bindkey '^Y' autosuggest-accept

fzf-tab-complete() {
  zle expand-or-complete
}
zle -N fzf-tab-complete
bindkey '\e[Z' fzf-tab-complete # Shift+Tab
bindkey '\e '  fzf-tab-complete # Alt+Space (Alt is mapped from Cmd in ghostty)