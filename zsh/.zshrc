# NOTE: oh-my-zsh template: ~/.oh-my-zsh/templates/zshrc.zsh-template

# NOTE: Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# NOTE: Update PATH variable
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# export GEM_HOME="$(gem env user_gemhome)"
# export PATH="$PATH:$GEM_HOME/bin"

# # Spicetify
# PATH=$PATH:/home/hareki/.spicetify

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load rbenv automatically
eval "$(rbenv init - zsh)"

# NOTE: Stow config
export STOW_REPO="$HOME/Repositories/personal/dotfiles"
sync-d() {
    if [ -d "$STOW_REPO/$1" ]; then
        cd "$STOW_REPO" || return
        stow "$1" -t ~
        cd - 
    else
        echo "Directory $STOW_REPO/$1 does not exist."
    fi
}

sync-g() {
  cd "$STOW_REPO" || return
  if git status --porcelain | grep -q .; then
    git add .
    git commit -m "updated via script at $(date +"%d/%m/%Y | %a %I:%M %p")"
    git push
  else
    echo "nothing to commit, working tree clean"
  fi
  cd -
}


# NOTE: Enable vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey '^E' autosuggest-accept


# Change cursor shape for different vi modes.
# https://gist.github.com/LukeSmithxyz/e62f26e55ea8b0ed41a65912fbebbe52
zle-keymap-select() {
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
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# NOTE: Aliases and util functions
alias cls="colorls"
alias rez="source ~/.zshrc && zsh"
cl() { cd "$@" && cls; }

nvcd() {
  # 1. The `env TERM=wezterm` is for https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
  # 2. Have to use the `command` to explicitly call a command without triggering the alias.
    if [[ -z $1 ]]; then
      command env TERM=wezterm nvim
      return 0
    fi

    if [[ -d $1 ]]; then
      cd "$1" && command env TERM=wezterm nvim .
      return 0
    fi

    command env TERM=wezterm nvim "$1"
}
alias nvim="nvcd"

fv() {
  # Default values
  local type=""
  local root_dir="$HOME"  # Default to home directory
  local change_dir=0  # Flag to indicate whether to use 'cd'

  # Help message
  local help_message="Usage: fv [options] [path]
  
Options:
  -d            List directories only (uses '--type directory')
  -f            List files only (uses '--type file')
  -c            Change to the selected directory (uses 'cd' instead of 'nvim')
  -h            Show this help message
  
If [path] is provided, it will be used as the root directory to begin the search. If omitted, the default is \$HOME."

  # Parse options
  while getopts ":dfch" opt; do
    case $opt in
      d) type="directory" ;;       # Option -d for directories
      f) type="file" ;;            # Option -f for files
      c) change_dir=1; type="directory" ;;  # Option -c for changing directories
      h) echo "$help_message"; return 0 ;;  # Option -h to display help
      \?) echo "Invalid option: -$OPTARG" >&2; return 1 ;;  # Invalid option handling
      :) echo "Option -$OPTARG requires an argument." >&2; return 1 ;;  # Missing argument
    esac
  done

  # Shift to check for positional argument (path)
  shift $((OPTIND - 1))

  # If a path is provided as an argument, use it
  if [[ -n "$1" ]]; then
    root_dir="$1"
  fi

  # Build the fd command
  local fd_command=(fd --hidden --exclude .git --exclude node_modules --exclude mnt)
  [[ -n "$type" ]] && fd_command+=(--type "$type")
  fd_command+=(".*" "$root_dir")

  # Use fd to list files/directories and fzf to select
  local file
  file=$("${fd_command[@]}" | fzf-tmux -p --reverse)

  # Check if the selection is empty (Ctrl-C or Esc was pressed)
  if [[ -z "$file" ]]; then
    echo "Selection canceled, no file opened."
    return 0
  fi

  # If -c option is provided, change to the selected directory
  if [[ $change_dir -eq 1 ]]; then
    cd "$file" || return 1
    echo "Changed directory to $file"
  else
    # Otherwise, open the file/directory in nvim
    nvim "$file"
  fi
}

# NOTE: NVM Configs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# NOTE: Enable searching command history with fzf
source <(fzf --zsh)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# NOTE: Fix slowness of pastes with zsh-syntax-highlighting.zsh
# https://gist.github.com/magicdude4eva/2d4748f8ef3e6bf7b1591964c201c1ab
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
}

pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# NOTE: Surface1(bg) and Yellow(fg) from Catppuchin Mocha
# Couldn't get it to just change the bg color and leave the bg color as is, so I chose a foreground color myself
zle_highlight=(region:bg=#45475a,fg=#f9e2af)

# NOTE: Start ssh server on startup for wezterm ssh
if ! pgrep -x "sshd" > /dev/null
then
    sudo /usr/sbin/sshd
fi

# NOTE: Set default editor
export EDITOR='nvim'
export VISUAL='nvim'

clear
