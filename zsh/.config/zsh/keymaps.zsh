bindkey '^[f' atuin-search

# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

bindkey '^Y' autosuggest-accept

# Replay Tab, so these follow its binding: expand-or-complete until deferred fzf-tab
# loads and rebinds Tab to fzf-tab-complete
bindkey -s '\e[Z' '^I' # Shift+Tab
bindkey -s '\e '  '^I' # Alt+Space (Alt is mapped from Cmd in ghostty)
