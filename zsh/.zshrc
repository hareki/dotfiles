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

# Re-apply .zshenv's PATH order: brew shellenv prepends Homebrew, and login
# shells ran /etc/zprofile's path_helper, which moved the system dirs in front
path=($user_path $path)

# Load configuration files, order matters
for cfg in aliases vi-mode keymaps options evals tty-guard; do
  source $__zsh_config_dir/$cfg.zsh
done

# Autoload util functions when needed; compinit picks up the custom completions
# in compdefs/ via their `#compdef` tag
fpath=($__zsh_config_dir/{compdefs,functions} $fpath)
autoload -Uz $__zsh_config_dir/functions/*(.N:t)

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
