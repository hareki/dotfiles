
# Enable vi mode
bindkey -v

# Change cursor shape for different vi modes.
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
zle-keymap-select() {
  if [[ ${KEYMAP} == vicmd ]] ||
    [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
    [[ ${KEYMAP} == viins ]] ||
    [[ ${KEYMAP} = '' ]] ||
    [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

zle-line-init() {
  zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
  echo -ne "\e[5 q"
}
zle -N zle-line-init

echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

typeset -f osc52_copy >/dev/null || osc52_copy() {
  local data; data=$(printf %s "$1" | base64)
  printf '\e]52;c;%s\a' "$data"
}

is_local() { [[ -z "$SSH_TTY" ]]; }


vi_yank_osc52() { zle .vi-yank;              osc52_copy "$CUTBUFFER" }
vi_yank_eol_osc52() { zle .vi-yank-eol;      osc52_copy "$CUTBUFFER" }
vi_yank_whole_line_osc52() { zle .vi-yank-whole-line; osc52_copy "$CUTBUFFER" }

zle -N vi-yank vi_yank_osc52
zle -N vi-yank-eol vi_yank_eol_osc52
zle -N vi-yank-whole-line vi_yank_whole_line_osc52

vi_put_after_smart() {
  if is_local; then
    local prev=$CUTBUFFER; CUTBUFFER="$(pbpaste)"; zle .vi-put-after;  CUTBUFFER=$prev
  else
    zle .vi-put-after
  fi
}
vi_put_before_smart() {
  if is_local; then
    local prev=$CUTBUFFER; CUTBUFFER="$(pbpaste)"; zle .vi-put-before; CUTBUFFER=$prev
  else
    zle .vi-put-before
  fi
}

zle -N vi-put-after vi_put_after_smart
zle -N vi-put-before vi_put_before_smart

# Copy on visual `x` (delete selection + copy via OSC52)
visual_x_copy() {
  zle .kill-region || return 0
  osc52_copy "$CUTBUFFER"   # uses the helper from the earlier setup
}
zle -N visual-x-copy visual_x_copy
bindkey -M visual 'x' visual-x-copy

# Set highlight color for region in vi mode: Surface1(bg) and Yellow(fg) from Catppuccin Mocha
# Couldn't get it to just change the bg color and leave the fg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#4f5164,fg=#f9e2af)