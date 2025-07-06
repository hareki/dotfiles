# precompile zshrc (if necessary) before executing it
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
export TERM='xterm-ghostty' # default value, it's just there purely for the "rez" alias

# An alternative to `mise activate --shims`
# Helpful if mise is not yet available at that point in time.
# Using this to have `node` on non-interactive shells as well
export PATH="$HOME/.local/share/mise/shims:$PATH"
