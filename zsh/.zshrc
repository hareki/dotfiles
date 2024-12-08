if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# Disable instant prompt for now, since I have lazy-loaded tons of stuff, the startup time is pretty good now (~150ms)
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Show labels for completions (pressing tab)
# zstyle ':completion:*' format '%d'
# zstyle ':completion:*' group-name ''

export PATH="/mnt/c/Windows:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0:$PATH"
export FNM_DIR="$HOME/.local/share/fnm"
[[ -d "$FNM_DIR" ]] && PATH="$FNM_DIR:$PATH"
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.local/share/fnm" ]] && PATH="$HOME/.local/share/fnm:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"

# The ssh-agent plugin just starts the ssh-agent, to work with multiple identities, follow this guide:
# https://gist.github.com/oanhnn/80a89405ab9023894df7
plugins=(zsh-autosuggestions zsh-syntax-highlighting ssh-agent autoupdate)

zstyle ':omz:update' mode auto      # update oh-my-zsh automatically without asking

# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/ssh-agent/README.md#powerline-10k-specific-settings
zstyle :omz:plugins:ssh-agent quiet yes
zstyle :omz:plugins:ssh-agent lazy yes

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS=8
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

source $ZSH/oh-my-zsh.sh

# 2x Ctrl-D to exit, see `bash-ctrl-d` function
export IGNOREEOF=2
__BASH_IGNORE_EOF=0

# Editor and Terminal Settings
export EDITOR='nvim'
export VISUAL='nvim'

# ======= Lazygit Color Settings =======
# This one's causing trouble with lazygit truecolor support
# export TERM='wezterm'

# For some reasons this one doesn't work: https://github.com/wez/wezterm/issues/875
# lazygit needs this information to display truecolor
export COLORTERM="truecolor"

# Override the color 241 (ANSI) to "blue" in catppuccin since lazygit uses this color for directory icon
# https://github.com/jesseduffield/lazygit/issues/3863
# https://github.com/folke/snacks.nvim/blob/7564a30cad803c01f8ecc15683a280d2f0e9bdb7/lua/snacks/lazygit.lua#L125
echo -ne "\033]4;241;#89b4fa\007"

# Dotfiles management
export STOW_REPO="$HOME/Repositories/personal/dotfiles"

# Redis
export REDIS_BIN_PATH=/usr/bin
export CLUSTER_HOST=127.0.0.1
export CLUSTER_PORT=3002
export NODES=6

export BAT_THEME="Catppuccin Mocha"
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

# `--no-user` flag only takes effect when using in combination with long format
# The column doesn't provide any useful information in a single user environment anyway
alias ls="eza --icons=always --no-user"

# [RE-Z]shrc
# echo '' is to simulate the p10k ruler, I basically use it as a blank line at the top,
# so that when the shell is ready after instant prompt the prompt won't be shifted.

# env -i ... is to hard reset the environment variables to empty, must retain the essential ones like TERM
# this is to make sure the new zsh instance that doesn't inherit any of the previously exported variables.

# --login is to make sure the new shell behaves exactly like the first time we open the terminal
alias rez="clear && echo '' && exec env -i TERM="$TERM" zsh --login"

# Enable vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey '^E' autosuggest-accept

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
  echo "$CUTBUFFER" | clip.exe
}
zle -N vi-yank-clip
bindkey -M vicmd 'y' vi-yank-clip

function vi-delete-clip {
  zle vi-delete
  echo "$CUTBUFFER" | clip.exe
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

# Make Ctrl-D terminate the shell only after a certain number of times: https://superuser.com/questions/1243138/why-does-ignoreeof-not-work-in-zsh
# Bash like Ctrl-D wrapper for IGNOREEOF
setopt ignore_eof
function bash-ctrl-d {
  if [[ $CURSOR == 0 && -z $BUFFER ]]
  then
    [[ -z $IGNOREEOF || $IGNOREEOF == 0 ]] && exit
    if [[ "$LASTWIDGET" == "bash-ctrl-d" ]]
    then
      (( --__BASH_IGNORE_EOF <= 0 )) && exit
    else
      (( __BASH_IGNORE_EOF = IGNOREEOF ))
    fi
  fi
}

zle -N bash-ctrl-d
bindkey '^D' bash-ctrl-d

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

# Start ssh server on startup for wezterm ssh
if ! pgrep -x "sshd" > /dev/null
then
  sudo /usr/sbin/sshd
fi

# ====== Wrapper functions to lazy load heavy stuff ======
eval "`zoxide init zsh`"

function tmuxinator {
  unset -f tmuxinator
  eval "`rbenv init - zsh`"
  tmuxinator "$@"
}

NODE_REQUIRED_COMMANDS=(node npm npx lazygit)

function unset_node_commands {
  for cmd in "${NODE_REQUIRED_COMMANDS[@]}"; do
    unset -f "$cmd" >/dev/null 2>&1
  done
}

for cmd in "${NODE_REQUIRED_COMMANDS[@]}"; do
  eval "
    function $cmd() {
      unset_node_commands
      eval \"\$(fnm env)\"
      $cmd \"\$@\"
    }
  "
done

function ensure_node_loaded {
  # Check if "node" is a shell function (used to lazy load Node.js) or not
  # If it is => Node.js is not loaded yet
  if typeset -f node > /dev/null; then
    if command -v fnm >/dev/null 2>&1; then
      eval "$(fnm env)"
      unset_node_commands
      
      # Verify that 'node' is now available
      if ! command -v node >/dev/null 2>&1; then
        echo "Error: Node.js could not be loaded via fnm." >&2
        return 1
      fi
    else
      echo "Error: fnm is not installed. Please install fnm to use nvim with Node.js plugins." >&2
      return 1
    fi
  fi
  return 0
}

# [N]eo[V]im and [C]hange [D]irectory
function nvcd {
  ensure_node_loaded || return 1

  # 1. The `env TERM=wezterm` is for https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
  # 2. Have to use the `command` to explicitly call a command without triggering the alias.
  if [[ -z $1 ]]; then
    command env TERM=wezterm nvim
    return 0
  fi

  if [[ -d $1 ]]; then
    z "$1" && command env TERM=wezterm nvim .
    return 0
  fi

  command env TERM=wezterm nvim "$1"
}

# Overshadows the nvim command to load Node.js via fnm first, and then run nvim
# Also setups alias for the actual command to `nvcd`
function nvim {
  ensure_node_loaded || return 1
  unset -f nvim
  alias nvim="nvcd"
  nvcd "$@"
}

# Autoload util functions when needed
functions_dir=~/.zsh/lazy-functions
fpath=($functions_dir $fpath)
for func in $functions_dir/*(.N); do
  autoload -Uz "${func:t}"
done

clear

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi
