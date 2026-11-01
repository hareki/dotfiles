ANTIDOTE_HOME="$HOME/.cache/antidote"
# What omz's libs and updater read from its own loader, which isn't used here
ZSH="$ANTIDOTE_HOME/github.com/ohmyzsh/ohmyzsh"
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"
# Settle p10k's SSH check as local, or it forks `who -m` (~2.5ms) in every shell on a new tty
[[ -n $SSH_CLIENT$SSH_TTY$SSH_CONNECTION ]] || export P9K_SSH=0 _P9K_SSH_TTY=$TTY

# The personal identity loads up front; ~/.ssh/config's AddKeysToAgent adds the rest on use
zstyle ':omz:plugins:ssh-agent' identities id_ed25519_personal
# A live inherited agent has the identity: no `ssh-add -l` + `ssh-keygen` check (~8ms)
kill -0 $SSH_AGENT_PID 2>/dev/null && zstyle ':omz:plugins:ssh-agent' lazy yes
# The plugin names its env file after this; exported to spare child shells the fork
[[ -n $SHORT_HOST ]] || export SHORT_HOST=$(scutil --get LocalHostName)

zstyle ':antidote:bundle:*' zcompile 'yes'
# Skip zsh-defer's precmd re-run and repaint. Only autosuggestions starts from a precmd hook,
# and the end of this file starts it directly
zstyle ':antidote:bundle:*' defer-options '-mpr'

# Completion-only flags: FZF_DEFAULT_OPTS also reaches zoxide's `zi` and plain fzf
zstyle ':fzf-tab:*' fzf-flags --height=13 --max-width=75 --border-label=' Completions '
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Wrap the widgets once at load instead of re-binding ~210 of them every precmd (~8ms)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Past 100 characters a fetch (a fork plus ~35ms of CPU) almost never finds a suggestion
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100

typeset -U fpath
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

# `brew shellenv zsh` written out, minus its `export PATH`: .zshenv has those dirs, and any
# PATH assignment discards the command hash the instant prompt filled (~1.3ms to refill)
export HOMEBREW_PREFIX=/opt/homebrew
export HOMEBREW_CELLAR=$HOMEBREW_PREFIX/Cellar HOMEBREW_REPOSITORY=$HOMEBREW_PREFIX
fpath[1,0]=/opt/homebrew/share/zsh/site-functions
export FPATH INFOPATH=/opt/homebrew/share/info:$INFOPATH
# The empty entry keeps man's default dirs, which cover Homebrew's, in the search
[[ -z $MANPATH ]] || manpath=('' $manpath)

# Moved in only on success: a failed clone's empty bundle would count as fresh, never retried
if [[ ! ~/.zplugins.bundled.zsh -nt ~/.zplugins ]]; then
  antidote bundle <~/.zplugins >|~/.zplugins.bundled.zsh.$$ \
    && mv -f ~/.zplugins.bundled.zsh.$$ ~/.zplugins.bundled.zsh \
    || rm -f ~/.zplugins.bundled.zsh.$$
fi
source ~/.zplugins.bundled.zsh

zstyle ':omz:update' mode auto
source $ZSH/tools/check_for_upgrade.sh

# omz's paste magic replays every pasted character through the widget chain (~330ms per 2KB)
# for the sake of URLs; zsh's own widget quotes a pasted URL in one pass
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# p10k captures stdout until the first prompt is expanded, and any output costs it a `cat`
# fork, so omz's title goes straight to the tty
_title_to_tty() { omz_termsupport_precmd >$TTY }
precmd_functions[(r)omz_termsupport_precmd]=_title_to_tty

# omz forks twice per prompt for an OSC 7 nothing reads: Ghostty's shell integration reports
# the cwd itself, tmux keeps it in an unused #{pane_path}, and nvim's terminal drops it
add-zsh-hook -d precmd omz_termsupport_cwd

# Queued last, so it wraps the deferred plugins' widgets. +s fetches a suggestion for anything
# typed ahead. The plugin's precmd hook alone would wait for the next prompt
zsh-defer -a +s _zsh_autosuggest_start
