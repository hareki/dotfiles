# precompile zshrc (if necessary) before executing it
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# Use MacOS keychain to store secrets
export SWEEPAPI_TOKEN=$(security find-generic-password -a "$USER" -s "SWEEPAPI_TOKEN" -w)

# Aliases needed in non-interactive shells, others should go in to aliases.zsh for performance
alias eza='eza --icons=always --color=always --no-user'
alias fdt='fd --type dir --hidden'
# Prevent fd from taking 100% CPU for long-running searches
alias fd='gtimeout 5s fd'

# An alternative to `mise activate --shims`
# Helpful if mise is not yet available at that point in time.
# Using this to have `node` on non-interactive shells as well
export PATH="$HOME/.local/share/mise/shims:$PATH"
