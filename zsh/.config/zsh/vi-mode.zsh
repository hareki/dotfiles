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
  if [[ ${KEYMAP} == vicmd ]] ||
    [[ $1 = 'block' ]]; then
    cursor_block
  elif [[ ${KEYMAP} == main ]] ||
    [[ ${KEYMAP} == viins ]] ||
    [[ ${KEYMAP} = '' ]] ||
    [[ $1 = 'beam' ]]; then
    cursor_beam
  fi
}
zle -N zle-keymap-select

zle-line-init() {
  zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
  cursor_beam
}
zle -N zle-line-init

cursor_beam
autoload -Uz add-zsh-hook
add-zsh-hook precmd cursor_beam

typeset -f osc52_copy >/dev/null || osc52_copy() {
  local data; data=$(printf %s "$1" | base64)
  printf '\e]52;c;%s\a' "$data"
}

is_local() { [[ -z "$SSH_TTY" ]]; }


vi_yank_osc52() { zle .vi-yank; osc52_copy "$CUTBUFFER"; cursor_block }
vi_yank_eol_osc52() { zle .vi-yank-eol; osc52_copy "$CUTBUFFER"; cursor_block }
vi_yank_whole_line_osc52() { zle .vi-yank-whole-line; osc52_copy "$CUTBUFFER"; cursor_block }

zle -N vi-yank vi_yank_osc52
zle -N vi-yank-eol vi_yank_eol_osc52
zle -N vi-yank-whole-line vi_yank_whole_line_osc52

vi_put_after_smart() {
  if is_local; then
    local prev=$CUTBUFFER; CUTBUFFER="$(pbpaste)"; zle .vi-put-after;  CUTBUFFER=$prev
  else
    zle .vi-put-after
  fi
  cursor_block
}
vi_put_before_smart() {
  if is_local; then
    local prev=$CUTBUFFER; CUTBUFFER="$(pbpaste)"; zle .vi-put-before; CUTBUFFER=$prev
  else
    zle .vi-put-before
  fi

  cursor_block
}

zle -N vi-put-after vi_put_after_smart
zle -N vi-put-before vi_put_before_smart

# Copy on visual `x` (delete selection + copy via OSC52)
visual_x_copy() {
  zle .kill-region || return 0
  osc52_copy "$CUTBUFFER"   # uses the helper from the earlier setup

  cursor_block
}

zle -N visual-x-copy visual_x_copy
bindkey -M visual 'x' visual-x-copy

# hjkl unused — arrow keys via keyboard layers
bindkey -M visual 'h' vi-yank           # h = yank (uses osc52 override from above)
bindkey -M visual 'k' vi-put-after      # k = put  (uses smart-paste override from above)

# Same swap in normal mode: hh = yank whole line (zsh doubles the operator), k = put
bindkey -M vicmd  'h' vi-yank           # h = yank operator; hh yanks the whole line (osc52 override)
bindkey -M vicmd  'k' vi-put-after      # k = put  (uses smart-paste override from above)

# Shift+V selects the whole current line in Visual mode.
# Native visual-line-mode leaves mark==cursor, so nothing highlights on a single-line buffer;
# instead go to beginning-of-line, enter char-wise Visual, then extend to end-of-line
select_whole_line() { zle .beginning-of-line; zle .visual-mode; zle .end-of-line }
zle -N select-whole-line select_whole_line
bindkey -M vicmd  'V' select-whole-line

# Set highlight color for region in vi mode: Surface1(bg) and Yellow(fg) from Catppuccin Mocha
# Couldn't get it to just change the bg color and leave the fg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#4f5164,fg=#f9e2af)
