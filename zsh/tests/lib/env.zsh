# Sourced by run.zsh, ab.zsh and the test files: scratch dirs, and scratch shells of the config that
# can't reach the live one. Each rule below once cost a leak or a false result:
#
# - Dummy API keys in the environment, so .zshenv skips the keychain. Never xtrace a boot (an xtrace
#   of .zshenv printed both real keys into a transcript), and never dump the environment (`ps -E`)
# - Every boot, and every test file run.zsh starts, begins from `env -i` with a scratch HOME: a
#   helper that inherited its caller's environment once booted ~15 real-config shells, ran the real
#   antidote bundle and read the real ssh-agent file
# - A scratch HOME laid out like stow (zt_home), so everything $HOME-relative moves with it: the
#   bundle's sources, every cache, the history. The plugin clones are a copy-on-write copy, since
#   antidote zcompiles into them; gitstatus, the built binaries and TPM's plugins are links
# - A short private TMPDIR: zsh-patina bakes the socket path of the shell that built its cache into
#   it (a cache built under another TMPDIR leaves highlighting off until the next clear), and a
#   socket path over 104 bytes fails silently
# - omz's update stamp is current, or the updater can pull the plugin clone
# - mise keeps its real dirs with installs off: under a moved data dir a shim recursion once spawned
#   ~3,500 processes
# - A private tmux server hosts each boot: zpty's 0x0 pty stalls p10k

zmodload zsh/datetime

# Test files inherit these from run.zsh, since their own HOME is a scratch dir
typeset -g ZT_REAL_HOME=${ZT_REAL_HOME:-$HOME} ZT_TMUX=${ZT_TMUX:-${commands[tmux]}}
typeset -g ZT_LIB=${${(%):-%x}:A:h}
# What a test file's commands find: the tmux build first (resurrect's scripts call `tmux` by name)
typeset -g ZT_PATH=${ZT_TMUX:h}:/usr/bin:/bin:/usr/sbin:/sbin
typeset -ga ZT_TIMEOUT=()
(( $+commands[gtimeout] )) && ZT_TIMEOUT=(gtimeout 600)

# Short and private: tmux and zsh-patina put sockets here
zt_tmpdir() {
  mktemp -d /tmp/zt.XXXXXX
}

# Stops what a test started under its scratch dir (tmux servers, zsh-patina daemons), then removes it
zt_cleanup() {
  local dir=$1 sock lock
  [[ $dir == /tmp/zt.?* && -d $dir ]] || return 0
  for sock in $dir/**/*(N=); do
    $ZT_TMUX -S $sock kill-server 2>/dev/null
  done
  for lock in $dir/**/zsh-patina/daemon.lock(N); do
    kill "$(<$lock)" 2>/dev/null
  done
  rm -rf $dir
}

# zt_home <home> <tree>: lays out <home> the way `sync-dots` lays out $HOME from <tree>, a repo root
# holding the zsh, p10k and tmux packages
zt_home() {
  local home=$1 tree=$2
  mkdir -p $home/{.config,.cache/zsh,.local/bin/shims,.tmux} || return 1
  ln -s $tree/zsh/{.zshenv,.zshrc,.zplugins,.hushlogin} $home/ &&
    ln -s $tree/zsh/.config/zsh $home/.config/zsh &&
    ln -s $tree/p10k/.p10k.zsh $home/.p10k.zsh &&
    ln -s $tree/tmux/.config/tmux $home/.config/tmux &&
    cp -cR $ZT_REAL_HOME/.cache/antidote $home/.cache/antidote &&
    ln -s $ZT_REAL_HOME/.cache/gitstatus $home/.cache/gitstatus &&
    ln -s $ZT_REAL_HOME/.local/opt $home/.local/opt &&
    ln -s $ZT_REAL_HOME/.tmux/plugins $home/.tmux/plugins || return 1
  print -r -- "LAST_EPOCH=$(( EPOCHSECONDS / 86400 ))" >$home/.cache/zsh/.zsh-update
}

# zt_env <home> <tmpdir>: sets reply to the environment a scratch boot starts from
zt_env() {
  local mise_cache=$ZT_REAL_HOME/Library/Caches/mise
  reply=(
    HOME=$1 USER=$USER LOGNAME=$USER SHELL=/bin/zsh LANG=${LANG:-en_US.UTF-8}
    PATH=/usr/bin:/bin:/usr/sbin:/sbin TMPDIR=$2/ TMUX_TMPDIR=$2
    MERCURY_API_KEY=dummy ANTHROPIC_API_KEY=dummy
    MISE_DATA_DIR=$ZT_REAL_HOME/.local/share/mise MISE_CONFIG_DIR=$ZT_REAL_HOME/.config/mise
    MISE_STATE_DIR=$ZT_REAL_HOME/.local/state/mise MISE_CACHE_DIR=$mise_cache
    MISE_NOT_FOUND_AUTO_INSTALL=false MISE_EXEC_AUTO_INSTALL=false MISE_TASK_RUN_AUTO_INSTALL=false
  )
}

# zt_boot <home> <dir> <tree>: boots the config laid out in <home> (by zt_home from <tree>) in a
# private tmux pane, first as a top-level login shell (SHLVL 1, outside tmux), then as a login shell
# started from it, and waits for each one's dump (dump.zsh) in <dir>/dump-1.txt and dump-2.txt
zt_boot() {
  local home=$1 dir=$2 tree=$3 sock=$2/tmux.sock
  mkdir -p $dir/tmp || return 1
  zt_env $home $dir/tmp
  # tmux runs the pane's command through $SHELL -c, which for zsh would read the config once more
  env -i $reply SHELL=/bin/sh $ZT_TMUX -S $sock -f /dev/null new-session -d -x 160 -y 50 -c $home \
    "exec env -u TMUX -u TMUX_PANE SHELL=/bin/zsh SHLVL=0 ZDOTDIR=$ZT_LIB/zdotdir ZT_DUMP_DIR=$dir ZT_TREE=$tree /bin/zsh -l" ||
    return 1
  zt_await $sock $dir/dump-1.txt || return 1
  $ZT_TMUX -S $sock send-keys 'zsh -l' Enter
  zt_await $sock $dir/dump-2.txt || return 1
  $ZT_TMUX -S $sock kill-server
}

# zt_await <socket> <file>: presses Enter in the pane every half second until <file> appears, since
# the dump runs at the first prompt after the deferred plugins have loaded
zt_await() {
  local sock=$1 file=$2 i
  for i in {1..60}; do
    [[ -s $file ]] && return 0
    $ZT_TMUX -S $sock send-keys Enter 2>/dev/null || break
    sleep 0.5
  done
  print -u2 -r -- "zt_await: no ${file:t} after 30s, the pane shows:"
  $ZT_TMUX -S $sock capture-pane -p 2>/dev/null | grep -v '^$' >&2
  return 1
}
