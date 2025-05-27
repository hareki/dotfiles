if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Show labels for completions (pressing tab)
# zstyle ':completion:*' format '%d'
# zstyle ':completion:*' group-name ''

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"
export ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"

zstyle ':omz:update' mode auto      # update oh-my-zsh automatically without asking

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS=8
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

# Set the root name of the plugins files (.txt and .zsh) antidote will use.
zsh_plugins="$HOME/.zsh_plugins"

# Ensure the .zsh_plugins.txt file exists so you can add plugins.
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

# Lazy-load antidote from its functions directory.
fpath=($(brew --prefix)/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zsh_plugins.txt is updated.
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Source your static plugins file.
source ${zsh_plugins}.zsh

autoload -Uz promptinit && promptinit && prompt powerlevel10k

# Dotfiles management
export STOW_REPO="$HOME/Repositories/personal/dotfiles"

# fzf-tmux command uses bash shell, causing the incorrect cursor shape due to "echo -ne '\e[5 q" not being executed.
# So we need to "echo -ne '\e[5 q" in the bash shell as well.
export BASH_ENV="$HOME/.fzf_bashrc"

# FZF Catppuccino Mocha theme with custom border color
export FZF_DEFAULT_OPTS=" \
--border=rounded --layout=reverse \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,border:#89b4fa \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--multi"

# Added/overriden options: --border=rounded --info=default
# Keep other default options, currently there's no way to merge the two
# https://github.com/ajeetdsouza/zoxide/issues/618
export _ZO_FZF_OPTS="--exact --no-sort --bind=ctrl-z:ignore,btab:up,tab:down --cycle --keep-right --border=rounded --height=45% --info=default --layout=reverse --tabstop=1 --exit-0"
# Extend fzf default options for zoxide
export _ZO_FZF_OPTS="$_ZO_FZF_OPTS $FZF_DEFAULT_OPTS"

alias lg="lazygit"

alias cd="z"
alias ..="z .."
alias ...="z ..."
alias ....="z ...."

alias yazi="ycd"
alias profile="time ZSH_DEBUGRC=1 zsh -i -c exit"
alias compz="zcompile ~/.zshrc"
alias cl="clear"
alias ez="nvim ~/.zshrc"
alias ezp="nvim ~/.zprofile"

# `--no-user` flag only takes effect when using in combination with long format
# The column doesn't provide any useful information in a single user environment anyway
alias ls="eza --icons=always --no-user"

# [RE-Z]shrc
# env -i ... is to hard reset the environment variables to empty, must retain the essential ones like TERM
# this is to make sure the new zsh instance that doesn't inherit any of the previously exported variables.

# --login is to make sure the new shell behaves exactly like the first time we open the terminal
# -i to ignore all current environment variables, must set the $TERM in .zprofile
alias rez="clear && exec env -i zsh --login"

# Enable vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey '^Y' autosuggest-accept

# Change cursor shape for different vi modes.
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
    [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
    [[ ${KEYMAP} == viins ]] ||
    [[ ${KEYMAP} = '' ]] ||
    [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select

function zle-line-init {
  zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
  echo -ne "\e[5 q"
}
zle -N zle-line-init

echo -ne '\e[5 q' # Use beam shape cursor on startup.
function preexec { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

function vi-yank-clip {
  zle vi-yank
  echo "$CUTBUFFER" | pbcopy
}
zle -N vi-yank-clip
bindkey -M vicmd 'y' vi-yank-clip

function vi-delete-clip {
  zle vi-delete
  echo "$CUTBUFFER" | pbcopy
}
zle -N vi-delete-clip
bindkey -M visual 'x' vi-delete-clip

function _sync_d_autocomplete {
  local -a dirs
  local repo_dir="$STOW_REPO"

  # Get a list of directories under $STOW_REPO excluding .git and feed them into completion
  dirs=(${(f)"$(fd --type d --max-depth 1 --exclude .git --base-directory $repo_dir --exec basename {})"})
  _describe 'stow directories' dirs
}
compdef _sync_d_autocomplete sync-d

function mz_insert_path {
  # Export the current PATH variable to the widget's environment
  local -x PATH="$PATH"

  local path
  path=$(mz -lp)

  if [[ -z "$path" ]]; then
    return 0
  fi

  # Insert the path into the command line at cursor position
  LBUFFER+="$path"
}

zle -N mz_insert_path
bindkey '^O' mz_insert_path


# Override the color 241 (ANSI) to "blue" in catppuccin since lazygit uses this color for directory icon
# https://github.com/jesseduffield/lazygit/issues/3863
# https://github.com/folke/snacks.nvim/blob/7564a30cad803c01f8ecc15683a280d2f0e9bdb7/lua/snacks/lazygit.lua#L125
echo -ne "\033]4;241;#89b4fa\007"

# Lazy load fzf fuzzy completion
function load_fzf_completion {
  unset -f load_fzf_completion
  source <(fzf --zsh)
  zle fzf-history-widget
}
zle -N load_fzf_completion
bindkey '^R' load_fzf_completion

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory

# Fix slowness of pastes with zsh-syntax-highlighting.zsh
# https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
function pasteinit {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

function pastefinish {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# Surface1(bg) and Yellow(fg) from Catppuchin Mocha
# Couldn't get it to just change the bg color and leave the bg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#45475a,fg=#f9e2af)


alias nvim="nvcd"
# [N]eo[V]im and [C]hange [D]irectory
function nvcd {
  # Have to use the `command` to explicitly call a command without triggering the alias.
  
  # No argument given
  if [[ -z $1 ]]; then
    command nvim
    return 0
  fi

  # Argument is directory => call zoxide first
  if [[ -d $1 ]]; then
    z "$1" && command nvim .
    return 0
  fi

  # Arugment is file
  command nvim "$1"
}


# Autoload util functions when needed
functions_dir=~/.zsh/lazy-functions
fpath=($functions_dir $fpath)
for func in $functions_dir/*(.N); do
  autoload -Uz "${func:t}"
done

_evalcache mise activate zsh
_evalcache zoxide init zsh


if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
