bindkey '^[f' atuin-search

# ctrl+shift+y
bindkey '\e[1;6Y' forward-word

bindkey '^Y' autosuggest-accept

# Ctrl+L wipes the scrollback as `clear` does; zle's own clear-screen sends no E3
clear_screen_and_scrollback() { clear && zle .clear-screen }
zle -N clear-screen clear_screen_and_scrollback

# Replay Tab, so these keep following its binding once deferred fzf-tab rebinds it
bindkey -s '\e[Z' '^I' # Shift+Tab
bindkey -s '\e '  '^I' # Alt+Space (Alt is mapped from Cmd in the rex config)
