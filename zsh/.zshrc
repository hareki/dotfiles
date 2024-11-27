# oh-my-zsh template: ~/.oh-my-zsh/templates/zshrc.zsh-template

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

export PATH="/mnt/c/Windows:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0:$PATH"
export FNM_DIR="$HOME/.local/share/fnm"
[[ -d "$FNM_DIR" ]] && PATH="$FNM_DIR:$PATH"
[[ -d "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && PATH="$HOME/.local/bin:$PATH"
[[ -d "/home/hareki/.local/share/fnm" ]] && PATH="/home/hareki/.local/share/fnm:$PATH"

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

# Editor and Terminal Settings
export EDITOR='nvim'
export VISUAL='nvim'

# ==== Lazygit Color Settings =====
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

# Aliases and util functions
alias lg="lazygit"
alias cd="z"

alias ..= "z .."
alias ...= "z ..."
alias ....= "z ...."

# [RE-Z]shrc
# echo '' is to simulate the p10k ruler (I use it as basically a blank line at the top)
# so that when the shell is ready (after instant prompt) the prompt won't be shifted 
alias rez="clear && echo '' && exec zsh"

# [S]ync-[D]otfiles
function sync-d {
  if [ -d "$STOW_REPO/$1" ]; then
    z "$STOW_REPO" || return
    stow "$1" -t ~
    z -  > /dev/null
  else
    echo "Directory $STOW_REPO/$1 does not exist."
  fi
}

function _sync_d_autocomplete {
  local -a dirs
  local repo_dir="$STOW_REPO"

  # Get a list of directories under $STOW_REPO excluding .git and feed them into completion
  dirs=(${(f)"$(fd --type d --max-depth 1 --exclude .git --base-directory $repo_dir --exec basename {})"})
  _describe 'stow directories' dirs
}
compdef _sync_d_autocomplete sync-d

# [S]ync [G]itHub
function sync-g {
  z "$STOW_REPO" || return
  
  # Check for uncommitted changes
  if git status --porcelain | grep -q .; then
    git add .
    git commit -m "Updated via sync-g at $(date +"%d/%m/%Y | %a %I:%M %p")"
    git push
  else
    # No uncommitted changes, check for unpushed commits
    if git log --branches --not --remotes | grep -q .; then
      echo "Unpushed commits found. Pushing now..."
      git push
    else
      echo "Nothing to commit, working tree clean, and all changes are pushed."
    fi
  fi

  z - || return
}

function explorer {
    if [ -z "$1" ]; then
      explorer.exe
    else
      explorer.exe "$(wslpath -w "$1")"
    fi
}

# [C]hange [D]irectory and [L]i[S]t
function cl { z "$@" && cls; }

# [N]eo[V]im and [C]hange [D]irectory
function nvcd {
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
alias nvim="nvcd"

function zn {
  z "$1" > /dev/null 2>&1 
  nvcd .
}

# [F]ind [B]ranch
function fb {
  # List branches, remove HEAD reference, leading spaces, asterisks, remove "remotes/origin/" prefix, and remove duplicates
  branch=$(git branch -a --sort=-committerdate | sed '/HEAD ->/d' | sed 's/^..//' | sed 's/remotes\/origin\///' | sort -u | fzf-tmux -p --reverse -w 60% -h 50%)

  if [[ -n $branch ]]; then
    # Check if the selected branch exists locally
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      # Checkout the local branch
      git checkout "$branch"
    else
      # Checkout a new local branch that tracks the remote branch
      git checkout -b "$branch" --track "remotes/origin/$branch"
    fi
  fi
}

# [M]y f[Z]f
# Heavily crafted with the help of ChatGPT
function mz {
  # Default values
  local type=""
  local root_dir="$HOME"  # Default to home directory
  local change_dir=0      # Flag to indicate whether to use 'cd'
  local use_preview=0     # Flag to indicate whether to use preview
  local output_path=0     # Flag for -l option

  # Help message
  local help_message="Usage: fv [OPTIONS] [PATH]

Options:
  -d, --directories   List directories only (uses '--type directory')
  -f, --files         List files only (uses '--type file')
  -p, --preview       Enable preview pane
  -c, --cd            Change to the selected directory (uses 'cd' instead of 'nvim')
  -l, --log           Output the selected path to the terminal input instead of opening it
  -h, --help          Show this help message

If [PATH] is provided, it will be used as the root directory to begin the search. If omitted, the default is \$HOME."

  # Parse options using getopts
  local opt
  # Reset OPTIND in case getopts has been used previously in the shell
  OPTIND=1
  while getopts ":dfpclh-:" opt; do
    case "$opt" in
      d)
        type="directory"
        ;;
      f)
        type="file"
        ;;
      p)
        use_preview=1
        ;;
      c)
        change_dir=1
        type="directory"
        ;;
      l)
        output_path=1
        ;;
      h)
        echo "$help_message"
        return 0
        ;;
      -)
        case "${OPTARG}" in
          directories)
            type="directory"
            ;;
          files)
            type="file"
            ;;
          preview)
            use_preview=1
            ;;
          cd)
            change_dir=1
            type="directory"
            ;;
          log)
            output_path=1
            ;;
          help)
            echo "$help_message"
            return 0
            ;;
          *)
            echo "Invalid option: --${OPTARG}" >&2
            return 1
            ;;
        esac
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND -1))

  # If both -c and -l are provided, throw an error
  if [[ $change_dir -eq 1 && $output_path -eq 1 ]]; then
    echo "Error: Options '-c/--cd' and '-l/--log' cannot be used together." >&2
    return 1
  fi

  # If a path is provided as an argument, use it
  if [[ -n "$1" ]]; then
    root_dir="$1"
  fi

  # Build the fd command
  local fd_command=(fd --hidden --exclude .git --exclude node_modules --exclude mnt)
  [[ -n "$type" ]] && fd_command+=(--type "$type")
  fd_command+=(".*" "$root_dir")

  # Common fzf-tmux options
  local fzf_options=(-p --reverse -w 60% -h 50%)

  # Add preview option if -p is provided
  if [[ $use_preview -eq 1 ]]; then
    fzf_options+=(
      --preview="bat --color=always --theme=\"Catppuccin Mocha\" {}"
      --preview-window=down:60%
      -h 80%  # Adjust height when using preview
    )
  fi

  # Use fd to list files/directories and fzf to select
  local file
  file=$("${fd_command[@]}" | fzf-tmux "${fzf_options[@]}")

  # Check if the selection is empty (Ctrl-C or Esc was pressed)
  if [[ -z "$file" ]]; then
    return 0
  fi

  # If -c option is provided, change to the selected directory
  if [[ $change_dir -eq 1 ]]; then
    z "$file" || return 1
    echo "Changed directory to $file"
  elif [[ $output_path -eq 1 ]]; then
    # Output the selected path
    echo "$file"
  else
    # Otherwise, open the file/directory in nvim
    nvim "$file"
  fi
}

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

# [Y]azi [C]hange [D]irectory
# Press q to quit and cd into the cwd
# Press Q to quit without changing directory
function ycd {
  local cwd_file
  cwd_file=$(mktemp)
  yazi --cwd-file="$cwd_file" "$@"
  if [ -f "$cwd_file" ]; then
    z "$(cat "$cwd_file")" || return
    rm "$cwd_file"
  fi
}

alias yazi="ycd"

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

eval "`zoxide init zsh`"

# I'm only using rbenv to run tmuxinator for now so we can lazy-load it to gain a bit of performance (~150ms)
# eval "`rbenv init - zsh`"
function tmuxinator {
  unset -f tmuxinator
  eval "`rbenv init - zsh`"
  tmuxinator "$@"
}

# Can't do the same for node since many commands depend on it (~100ms)
eval "`fnm env`"

clear
