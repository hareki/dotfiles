ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"
ANTIDOTE_HOME="$HOME/.cache/antidote"
# What omz's libs and updater read from its own loader, which isn't used here
ZSH="$ANTIDOTE_HOME/github.com/ohmyzsh/ohmyzsh"
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"
# Settle p10k's SSH check as local, or it forks `who -m` (~2.5ms) in every shell on a new tty
[[ -n $SSH_CLIENT$SSH_TTY$SSH_CONNECTION ]] || export P9K_SSH=0 _P9K_SSH_TTY=$TTY

# mroth/evalcache minus the md5 fork: keyed by args alone, so function body edits go stale
_evalcache() {
  local cache="$ZSH_EVALCACHE_DIR/init-${${(j:-:)@}//[^A-Za-z0-9_.-]/_}.sh"
  if [[ ! -s $cache ]]; then
    mkdir -p "$ZSH_EVALCACHE_DIR"
    # Per-shell temps are moved in whole, so shells started together (tmuxinator) can't
    # clobber or half-read them; `rm init-*` skips the dot, and two-arg zcompile survives mv
    local tmp="${cache:h}/.${cache:t}.$$"
    "$@" >"$tmp" || { rm -f "$tmp"; print -u2 "_evalcache: '$*' failed"; return 1 }
    mv -f "$tmp" "$cache"
    zcompile "$tmp.zwc" "$cache" && mv -f "$tmp.zwc" "$cache.zwc"
  fi
  source "$cache"
}

# `yay` and `build` call this, since updated tools may emit different init output
_evalcache_clear() {
  rm -f "$ZSH_EVALCACHE_DIR"/init-*(N)
}

# The personal identity loads up front; ~/.ssh/config's AddKeysToAgent adds the rest on use
zstyle ':omz:plugins:ssh-agent' identities id_ed25519_personal
zstyle ':omz:plugins:ssh-agent' quiet yes
# A live inherited agent has the identity: no `ssh-add -l` + `ssh-keygen` check (~8ms)
kill -0 $SSH_AGENT_PID 2>/dev/null && zstyle ':omz:plugins:ssh-agent' lazy yes
# The plugin names its env file after this; exported to spare child shells the fork
[[ -n $SHORT_HOST ]] || export SHORT_HOST=$(scutil --get LocalHostName)

zstyle ':antidote:bundle:*' zcompile 'yes'
# Skip zsh-defer's precmd re-run and repaint: only autosuggestions starts from a precmd hook
zstyle ':antidote:bundle:ohmyzsh/ohmyzsh' defer-options '-mpr'
zstyle ':antidote:bundle:Aloxaf/fzf-tab' defer-options '-mpr'

# Completion-only flags: FZF_DEFAULT_OPTS also reaches zoxide's `zi` and plain fzf
zstyle ':fzf-tab:*' fzf-flags --height=13 --max-width=75 --border-label=' Completions '
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Wrap the widgets once at load instead of re-binding ~210 of them every precmd (~8ms)
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

typeset -U fpath
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

_evalcache /opt/homebrew/bin/brew shellenv
# Re-apply .zshenv's PATH order: brew shellenv prepends Homebrew
path=($user_path $path)

fpath=($__zsh_config_dir/{compdefs,functions} $fpath)
# Ahead of the bundle, since omz's lib/directories.zsh calls compdef. A changed fpath dir has
# a new mtime, which spares compinit's own check (-C) its glob of every `_*` file (~5ms)
ZSH_COMPDUMP=$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION
() {
  local dir
  for dir in $fpath; do
    [[ $dir -nt $ZSH_COMPDUMP ]] && rm -f $ZSH_COMPDUMP
  done
}
# compinit only rebinds menu-select if complist has defined it
zmodload zsh/complist
autoload -Uz compinit && compinit -C -d $ZSH_COMPDUMP
if [[ ! $ZSH_COMPDUMP.zwc -nt $ZSH_COMPDUMP ]]; then
  zcompile $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP && mv -f $ZSH_COMPDUMP.$$.zwc $ZSH_COMPDUMP.zwc
fi

# Moved in only on success: a failed clone's empty bundle would count as fresh, never retried
if [[ ! ~/.zplugins.bundled.zsh -nt ~/.zplugins ]]; then
  antidote bundle <~/.zplugins >|~/.zplugins.bundled.zsh.$$ \
    && mv -f ~/.zplugins.bundled.zsh.$$ ~/.zplugins.bundled.zsh \
    || rm -f ~/.zplugins.bundled.zsh.$$
fi
source ~/.zplugins.bundled.zsh

zstyle ':omz:update' mode auto
source $ZSH/tools/check_for_upgrade.sh

# omz's lib/theme-and-appearance.zsh exports LS_COLORS, which eza would apply over its theme
unset LS_COLORS

# fzf-tab needs zsh's menu off to capture the unambiguous prefix; omz sets `menu select`
# under this pattern, which outranks ':completion:*', so this must follow the bundle
zstyle ':completion:*:*:*:*:*' menu no

# omz forks twice per prompt to URL-encode $HOST and $PWD; p10k's encoder needs no fork ((%)
# undoes its `%%`). Still emitted every prompt, so the cwd survives `reset` and tmux reattach
omz_termsupport_cwd() {
  if [[ $PWD != $_termsupport_cwd_last ]]; then
    _termsupport_cwd_last=$PWD
    _p9k_url_escape $HOST$PWD
    _termsupport_cwd_seq=$'\e]7;file://'${(%)_p9k__ret}$'\e\\'
  fi
  printf '%s' "$_termsupport_cwd_seq"
}

# Defer omz's title and OSC 7 hooks past p10k's stdout capture: output costs it a `cat` fork
() {
  local -a hooks=(${(M)precmd_functions:#omz_termsupport_*})
  precmd_functions=(${precmd_functions:|hooks})
  zsh-defer -12dmszpr -c "precmd_functions+=($hooks); ${(j:; :)hooks}"
}
