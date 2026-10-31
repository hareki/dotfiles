ZSH_EVALCACHE_DIR="$HOME/.cache/.zsh-evalcache"
ANTIDOTE_HOME="$HOME/.cache/antidote"
# What omz's libs and updater read from its own loader, which isn't used here
ZSH="$ANTIDOTE_HOME/github.com/ohmyzsh/ohmyzsh"
ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d $ZSH_CACHE_DIR ]] || mkdir -p "$ZSH_CACHE_DIR"
# p10k forks `who -m` (~2.5ms) in every shell on a new tty to catch an SSH login whose
# SSH_* vars were lost (su on a remote host); without those vars, settle it as local
[[ -n $SSH_CLIENT$SSH_TTY$SSH_CONNECTION ]] || export P9K_SSH=0 _P9K_SSH_TTY=$TTY

# mroth/evalcache minus the per-call md5 fork, keyed by the sanitized args alone: fine for
# binaries with short, distinct args, but a function's body edits would go silently stale
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

# Updated tools may emit different `eval "$(tool init)"` output, so `yay` and
# `build` drop the evalcaches and the next shell regenerates them
_evalcache_clear() {
  rm -f "$ZSH_EVALCACHE_DIR"/init-*(N)
}

# Load the personal ssh identity up front; ~/.ssh/config adds the others on first
# use (AddKeysToAgent)
zstyle ':omz:plugins:ssh-agent' identities id_ed25519_personal
zstyle ':omz:plugins:ssh-agent' quiet yes
# A live inherited agent got it from the shell that found the agent, which spares this
# shell the plugin's `ssh-add -l` + `ssh-keygen` check (~8ms)
kill -0 $SSH_AGENT_PID 2>/dev/null && zstyle ':omz:plugins:ssh-agent' lazy yes
# The plugin names its env file after this; exported to spare child shells the fork
[[ -n $SHORT_HOST ]] || export SHORT_HOST=$(scutil --get LocalHostName)

zstyle ':antidote:bundle:*' zcompile 'yes'
# zsh-defer re-runs the precmd hooks and repaints after each deferred plugin, but only the
# last one needs that: autosuggestions starts from a precmd hook
zstyle ':antidote:bundle:ohmyzsh/ohmyzsh' defer-options '-mpr'
zstyle ':antidote:bundle:Aloxaf/fzf-tab' defer-options '-mpr'

# Completion-only flags live here rather than in FZF_DEFAULT_OPTS, which zoxide's
# `zi` and plain fzf read as well
zstyle ':fzf-tab:*' fzf-flags --height=13 --max-width=75 --border-label=' Completions '
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Wrap the widgets once at load instead of re-binding ~210 of them every precmd (~8ms);
# .zplugins loads it after every other widget-defining plugin, so none stays unwrapped
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

typeset -U fpath
fpath=(/opt/homebrew/opt/antidote/share/antidote/functions $fpath)
autoload -Uz antidote

_evalcache /opt/homebrew/bin/brew shellenv
# Re-apply .zshenv's PATH order: brew shellenv prepends Homebrew
path=($user_path $path)

# compinit picks up the custom completions in compdefs/ via their `#compdef` tag
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

# Built under a temp name and moved in only on success: a failed clone makes antidote
# emit an empty bundle, which would count as fresh and never be retried
if [[ ! ~/.zplugins.bundled.zsh -nt ~/.zplugins ]]; then
  antidote bundle <~/.zplugins >|~/.zplugins.bundled.zsh.$$ \
    && mv -f ~/.zplugins.bundled.zsh.$$ ~/.zplugins.bundled.zsh \
    || rm -f ~/.zplugins.bundled.zsh.$$
fi
source ~/.zplugins.bundled.zsh

zstyle ':omz:update' mode auto
source $ZSH/tools/check_for_upgrade.sh

# omz's lib/theme-and-appearance.zsh exports LS_COLORS, which eza would apply on top
# of its theme.yml (EZA_CONFIG_DIR, set in .zshenv)
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

# p10k holds stdout in a file until the first prompt, and a non-empty file costs it a `cat`
# fork, so omz's title and OSC 7 hooks start from the deferred queue, after the capture ends
() {
  local -a hooks=(${(M)precmd_functions:#omz_termsupport_*})
  precmd_functions=(${precmd_functions:|hooks})
  zsh-defer -12dmszpr -c "precmd_functions+=($hooks); ${(j:; :)hooks}"
}
