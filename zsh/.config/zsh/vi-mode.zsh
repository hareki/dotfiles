
# Enable vi mode
bindkey -v

# Change cursor shape for different vi modes.
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
function zle-keymap-select {
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

function zle-line-init {
  zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
  echo -ne "\e[5 q"
}
zle -N zle-line-init

echo -ne '\e[5 q' # Use beam shape cursor on startup.
function preexec { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

function vi-yank-clip {
  zle vi-yank
  echo "$CUTBUFFER" | pbcopy
}
zle -N vi-yank-clip
bindkey -M vicmd 'y' vi-yank-clip

function vi-delete-clip {
  zle vi-delete
  echo "$CUTBUFFER" | pbcopy
}
zle -N vi-delete-clip
bindkey -M visual 'x' vi-delete-clip

# Set highlight color for region in vi mode: Surface1(bg) and Yellow(fg) from Catppuccin Mocha
# Couldn't get it to just change the bg color and leave the bg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#45475a,fg=#f9e2af)