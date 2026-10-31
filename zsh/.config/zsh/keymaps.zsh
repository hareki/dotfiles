bindkey '^[f' atuin-search

# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

bindkey '^Y' autosuggest-accept

# Replay Tab, so these keep following its binding once deferred fzf-tab rebinds it
bindkey -s '\e[Z' '^I' # Shift+Tab
bindkey -s '\e '  '^I' # Alt+Space (Alt is mapped from Cmd in ghostty)
