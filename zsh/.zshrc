if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt appendhistory sharehistory

__zsh_config_dir=~/.config/zsh
source $__zsh_config_dir/plugins.zsh
_evalcache /opt/homebrew/bin/brew shellenv

# Load configuration files (the order matters)
for cfg in aliases vi-mode compdef keymaps env; do
  source $__zsh_config_dir/$cfg.zsh
done

# Autoload util functions when needed
functions_dir=$__zsh_config_dir/functions
fpath=($functions_dir $fpath)
for func in $functions_dir/*(.N); do
  autoload -Uz "${func:t}"
done

# evalcache doesn't play nice with `mise activate zsh` due to its dynamic nature, especially in tmux
# Performance penalty is negligible, fallback to use shims in non-interactive shells (check .zshenv)
# https://mise.jdx.dev/dev-tools/shims.html#shims-vs-path
# _evalcache mise activate zsh
eval "$(mise activate zsh)"

_evalcache zoxide init zsh
_evalcache atuin init zsh --disable-up-arrow

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
