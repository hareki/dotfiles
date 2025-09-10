# Show labels for completions (pressing tab)
# zstyle ':completion:*' format '%d'
# zstyle ':completion:*' group-name ''

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="powerlevel10k/powerlevel10k"
export ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"

export ANTIDOTE_HOME="$HOME/.cache/antidote"

zstyle ':omz:update' mode auto      # update oh-my-zsh automatically without asking
zstyle ':omz:plugins:ssh-agent' quiet yes
zstyle ':antidote:bundle:*' zcompile 'yes'

zstyle ':fzf-tab:*' fzf-flags --height=11
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_CUSTOM_AUTOUPDATE_NUM_WORKERS=8
ZSH_CUSTOM_AUTOUPDATE_QUIET=true

# Nvim built-in terminal doesn't support colored underlines 
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#cdd6f4'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#cdd6f4'
# Remove bold style
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
ZSH_HIGHLIGHT_STYLES[unknown-command]='fg=red'

# Set the root name of the plugins files (.txt and .zsh) antidote will use.
zsh_plugins="$HOME/.zplugins"
bundled_zsh_plugins="${zsh_plugins}.bundled.zsh"

# Lazy-load antidote from its functions directory.
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zplugins is updated.
if [[ ! ${bundled_zsh_plugins} -nt ${zsh_plugins} ]]; then
  antidote bundle <${zsh_plugins} >|${bundled_zsh_plugins}
fi

# Source your static plugins file.
source ${bundled_zsh_plugins}
# Comment guide in `zsh_plugins.txt` file from the antidote docs (https://antidote.sh/)
# Special treatment for prompt plugins
autoload -Uz promptinit && promptinit && prompt powerlevel10k

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
