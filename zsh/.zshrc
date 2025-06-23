if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export STOW_REPO="$HOME/Repositories/personal/dotfiles"

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt appendhistory sharehistory

__zsh_config_dir=~/.config/zsh
source $__zsh_config_dir/plugins.zsh
_evalcache /opt/homebrew/bin/brew shellenv

# This is for spicetify and lazygit, which only require in interactive shells
PATH="$PATH:$HOME/.spicetify:$HOME/go/bin"

# Load configuration files (the order matters)
for cfg in aliases vi-mode compdef keymaps fzf zoxide; do
  source $__zsh_config_dir/$cfg.zsh
done

# Autoload util functions when needed
functions_dir=$__zsh_config_dir/functions
fpath=($functions_dir $fpath)
for func in $functions_dir/*(.N); do
  autoload -Uz "${func:t}"
done

function vivid_ls {                     
  local theme=${1:-catppuccin-mocha} 
  local colors=$(vivid generate "$theme") || return
  printf 'export LS_COLORS=%q\n' "$colors"
}

_evalcache mise activate zsh
_evalcache zoxide init zsh
_evalcache atuin init zsh --disable-up-arrow
_evalcache vivid_ls catppuccin-mocha

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi