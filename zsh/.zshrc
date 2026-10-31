# Emit beam cursor to override Neovim's :terminal default cursor block
[[ -t 1 ]] && print -n $'\e[5 q'

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Profile shell startup time
# zsh-bench would be more accurate, but I just care about startup time
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

source ~/.p10k.zsh

__zsh_config_dir=$XDG_CONFIG_HOME/zsh
source $__zsh_config_dir/plugins.zsh

# Load configuration files, order matters
for cfg in aliases vi-mode keymaps options evals tty-guard; do
  source $__zsh_config_dir/$cfg.zsh
done

autoload -Uz $__zsh_config_dir/functions/*(.N:t)
unset __zsh_config_dir cfg

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
