# Emit beam cursor to override Neovim's :terminal default cursor block
[[ -t 1 ]] && print -n $'\e[5 q'

# Profile shell startup time
# zsh-bench would be more accurate, but I just care about startup time
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

source ~/.p10k.zsh

# Load configuration files, order matters
for cfg in plugins aliases vi-mode keymaps options completion evals tty-guard; do
  source $XDG_CONFIG_HOME/zsh/$cfg.zsh
done
unset cfg

autoload -Uz $XDG_CONFIG_HOME/zsh/functions/*(.N)

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
