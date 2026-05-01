# precompile zshrc (if necessary) before executing it
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc
fi

export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR='nvim'
export VISUAL='nvim'
# Use MacOS keychain to store secrets
# export SWEEPAPI_TOKEN=$(security find-generic-password -a "$USER" -s "SWEEPAPI_TOKEN" -w)

# Aliases needed in non-interactive shells, others should go in to aliases.zsh for performance
alias eza='eza --icons=always --color=always --no-user'
alias fdt='fd --type dir --hidden'
# Prevent fd from taking 100% CPU for long-running searches
alias fd='gtimeout 5s fd'

# Append commands to use in non-interactive shells
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin/shims:$HOME/.local/bin:$PATH"
