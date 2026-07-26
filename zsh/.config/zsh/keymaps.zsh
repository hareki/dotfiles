bindkey '^[f' atuin-search

# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

bindkey '^Y' autosuggest-accept

# fzf-tab (deferred) defines the fzf-tab-complete widget once it loads
bindkey '\e[Z' fzf-tab-complete # Shift+Tab
bindkey '\e '  fzf-tab-complete # Alt+Space (Alt is mapped from Cmd in ghostty)