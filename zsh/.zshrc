# Emit beam cursor to override Neovim's :terminal default cursor block
[[ -t 1 ]] && print -n $'\e[5 q'

# Load p10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Profile shell startup time
# zsh-bench would be more accurate, but I just care about startup time
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Run `p10k configure` or edit ~/.p10k.zsh directly to customize p10k prompt
source ~/.p10k.zsh

__zsh_config_dir=$XDG_CONFIG_HOME/zsh
source $__zsh_config_dir/plugins.zsh
_evalcache /opt/homebrew/bin/brew shellenv

# Restore shims precedence so same-name wrappers win over Homebrew binaries
path=($shim_paths $path)

# Load configuration files, order matters
for cfg in aliases vi-mode keymaps options evals; do
  source $__zsh_config_dir/$cfg.zsh
done

# Autoload util functions when needed
functions_dir=$__zsh_config_dir/functions
fpath=($functions_dir $fpath)
autoload -Uz $functions_dir/*(.N:t)

# Custom completions, picked up by compinit via their `#compdef` tag
fpath=($__zsh_config_dir/compdefs $fpath)

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
