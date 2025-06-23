# precompile zshrc (if necessary) before executing it
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
export TERM='xterm-ghostty' # default value, it's just there purely for the "rez" alias