if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export STOW_REPO="$HOME/Repositories/personal/dotfiles"
# From image.nvim, to make sure ImageMagick work properly
export DYLD_FALLBACK_LIBRARY_PATH="opt/homebrew/lib:$DYLD_FALLBACK_LIBRARY_PATH"

# Prevent the dollar sign at the start when restoring sessions with tmux-resurrect
# https://unix.stackexchange.com/questions/167582/why-zsh-ends-a-line-with-a-highlighted-percent-symbol
export PROMPT_EOL_MARK=''

export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt appendhistory sharehistory

__zsh_config_dir=~/.config/zsh
source $__zsh_config_dir/plugins.zsh
_evalcache /opt/homebrew/bin/brew shellenv

# The mise shims path we set in .zshenv is overwritten by homebrew
PATH="$PATH:$HOME/.local/share/mise/shims:$HOME/.local/bin/shims:$HOME/.local/bin"

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

vivid_ls() {                     
  local theme=${1:-catppuccin-mocha} 
  local colors=$(vivid generate "$theme") || return
  printf 'export LS_COLORS=%q\n' "$colors"
}

# Don't work well with tmux, it doesn't update the $PATH, have to call "rez"
# Currently using shims instead, it has some limitations that don't affect me for now
# A plus side is that it works with non-interactive shell as well
# https://mise.jdx.dev/dev-tools/shims.html#shims-vs-path
# _evalcache mise activate zsh

_evalcache zoxide init zsh
_evalcache atuin init zsh --disable-up-arrow
_evalcache vivid_ls catppuccin-mocha

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
