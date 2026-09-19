# Enable vi mode
bindkey -v

# Make <Esc> switch modes instantly. The default KEYTIMEOUT (40 = 400ms) makes zle pause after
# Esc to see whether it begins a multi-key sequence (arrow keys, bracketed paste, etc. all start
# with ^[). 1 = 10ms is imperceptible, and real escape sequences still match because the terminal
# delivers them as a single burst that is already buffered when zle reads it.
KEYTIMEOUT=1

# Change cursor shape for different vi modes.
cursor_block() { echo -ne '\e[1 q'; }
cursor_beam()  { echo -ne '\e[5 q'; }

# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
zle-keymap-select() {
  if [[ $KEYMAP == vicmd ]]; then
    cursor_block
  elif [[ $KEYMAP == (main|viins|'') ]]; then
    cursor_beam
  fi
}
zle -N zle-keymap-select

zle-line-init() {
  cursor_beam
}
zle -N zle-line-init

osc52_copy() {
  local data; data=$(printf %s "$1" | base64)
  printf '\e]52;c;%s\a' "$data"
}

# One function serves several widgets: $WIDGET holds the name it was invoked as,
# so `zle .$WIDGET` dispatches to the matching builtin
vi_yank_osc52() { zle .$WIDGET; osc52_copy "$CUTBUFFER"; cursor_block }

zle -N vi-yank vi_yank_osc52
zle -N vi-yank-eol vi_yank_osc52
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
  cursor_block
}

zle -N vi-put-after vi_put_smart
zle -N vi-put-before vi_put_smart

# hjkl are unused (arrow keys come from keyboard layers), so h = yank and k = put.
# In normal mode `h` is the yank operator, so `hh` yanks the whole line
bindkey -M visual 'h' vi-yank
bindkey -M visual 'k' vi-put-after
bindkey -M vicmd  'h' vi-yank
bindkey -M vicmd  'k' vi-put-after

# Shift+V selects the whole current line in Visual mode.
# Native visual-line-mode leaves mark==cursor, so nothing highlights on a single-line buffer;
# instead go to beginning-of-line, enter char-wise Visual, then extend to end-of-line
select_whole_line() { zle .beginning-of-line; zle .visual-mode; zle .end-of-line }
zle -N select-whole-line select_whole_line
bindkey -M vicmd  'V' select-whole-line

# Set highlight color for region in vi mode: Surface1(bg) and Yellow(fg) from Catppuccin Mocha
# Couldn't get it to just change the bg color and leave the fg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#4f5164,fg=#f9e2af)
