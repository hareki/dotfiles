bindkey -v

# 10ms, so <Esc> switches modes at once; escape sequences still match, arriving in one burst
KEYTIMEOUT=1

# Change cursor shape for different vi modes.
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
_cursor_shape() { [[ $KEYMAP == vicmd ]] && echo -ne '\e[1 q' || echo -ne '\e[5 q' }

# Hooks, since `zle -N zle-line-init` would drop omz's `echoti smkx`, which Home/End need
# outside tmux. The `_` prefix keeps zsh-autosuggestions from wrapping the hook widgets
autoload -Uz add-zle-hook-widget
add-zle-hook-widget keymap-select _cursor_shape
add-zle-hook-widget line-init _cursor_shape

osc52_copy() { printf '\e]52;c;%s\a' "$(printf %s "$1" | base64)" }

# `zle .$WIDGET` runs the builtin the invoked widget shadows. A cancelled yank (`h` then Esc)
# skips the copy (the old yank would land on the clipboard) but exits 0, or zle would beep
vi_yank_osc52() { if zle .$WIDGET; then osc52_copy "$CUTBUFFER"; fi }

zle -N vi-yank vi_yank_osc52
zle -N vi-yank-whole-line vi_yank_osc52
# Visual `x` deletes the selection and copies it the same way
zle -N kill-region vi_yank_osc52
bindkey -M visual 'x' kill-region

vi_put_smart() {
  # Paste from the system clipboard locally; over SSH, from zle's own cut buffer
  if [[ -z $SSH_TTY ]]; then
    local prev=$CUTBUFFER; CUTBUFFER="$(pbpaste)"; zle .$WIDGET; CUTBUFFER=$prev
  else
    zle .$WIDGET
  fi
}

zle -N vi-put-after vi_put_smart
zle -N vi-put-before vi_put_smart

# hjkl are unused (arrow keys come from keyboard layers), so h = yank and k = put.
# In normal mode `h` is the yank operator, so `hh` yanks the whole line
bindkey -M visual 'h' vi-yank
bindkey -M visual 'k' vi-put-after
bindkey -M vicmd  'h' vi-yank
bindkey -M vicmd  'k' vi-put-after

# Native visual-line-mode leaves mark==cursor, highlighting nothing on a single-line buffer
select_whole_line() { zle .beginning-of-line; zle .visual-mode; zle .end-of-line }
zle -N select-whole-line select_whole_line
bindkey -M vicmd  'V' select-whole-line

# Catppuccin Mocha Yellow on a Surface1/Surface2 shade; bg alone can't keep the text's color
zle_highlight=(region:bg=#4f5164,fg=#f9e2af)
