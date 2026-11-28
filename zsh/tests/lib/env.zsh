# Sourced by run.zsh, ab.zsh and the test files: scratch dirs, and scratch shells of the config that
# can't reach the live one. Each rule below once cost a leak or a false result:
#
# - Dummy API keys in the environment, so .zshenv skips the keychain (tests/overrides.zsh checks that
#   a boot holds no other key). Never xtrace a boot (an xtrace of .zshenv printed both real keys into
#   a transcript), and never dump the environment (`ps -E`)
# - Every boot, and every test file run.zsh starts, begins from `env -i` with a scratch HOME: a
#   helper that inherited its caller's environment once booted ~15 real-config shells, ran the real
#   antidote bundle and read the real ssh-agent file
# - A scratch HOME laid out like stow (zt_home), so everything $HOME-relative moves with it: the
#   bundle's sources, every cache, the history. The plugin clones are a copy-on-write copy, since
#   antidote zcompiles into them; gitstatus and the built binaries are links
# - A short private TMPDIR: zsh-patina bakes the socket path of the shell that built its cache into
#   it (a cache built under another TMPDIR leaves highlighting off until the next clear), and a
#   socket path over 104 bytes fails silently
# - omz's update stamp is current, or the updater can pull the plugin clone
# - mise keeps its real dirs with installs off: under a moved data dir a shim recursion once spawned
#   ~3,500 processes
# - A private Rex server hosts each boot: zpty's 0x0 pty stalls p10k, and the real server's sessions
#   stay out of reach

zmodload zsh/datetime

# Test files inherit these from run.zsh, since their own HOME is a scratch dir
typeset -g ZT_REAL_HOME=${ZT_REAL_HOME:-$HOME} ZT_REX=${ZT_REX:-${commands[rex]}}
typeset -g ZT_LIB=${${(%):-%x}:A:h}
# What a test file's commands find
typeset -g ZT_PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Short and private: Rex and zsh-patina put sockets here
zt_tmpdir() {
  mktemp -d /tmp/zt.XXXXXX
}

# Stops what a test started under its scratch dir (Rex servers, zsh-patina daemons), then removes it
zt_cleanup() {
  local dir=$1 lock
  [[ $dir == /tmp/zt.?* && -d $dir ]] || return 0
  for lock in $dir/**/rex.pid(N) $dir/**/zsh-patina/daemon.lock(N); do
    kill "$(<$lock)" 2>/dev/null
  done
  # Shells and daemons still exiting can write in it (history, sockets) while it goes
  repeat 20; do
    rm -rf $dir 2>/dev/null && return 0
    sleep 0.2
  done
  rm -rf $dir
}

# zt_home <home> <tree>: lays out <home> the way `sync-dots` lays out $HOME from <tree>, a repo root
# holding the zsh and p10k packages
zt_home() {
  local home=$1 tree=$2
  # Every top-level dot file the zsh package holds, bar the ones stow leaves out
  local -a dotfiles=($tree/zsh/.*(.N))
  dotfiles=(${dotfiles:#*/(.DS_Store|.stow-local-ignore)})
  mkdir -p $home/{.config,.cache/zsh,.local/bin/shims} || return 1
  (( $#dotfiles )) && ln -s $dotfiles $home/ &&
    ln -s $tree/zsh/.config/zsh $home/.config/zsh &&
    ln -s $tree/p10k/.p10k.zsh $home/.p10k.zsh &&
    cp -cR $ZT_REAL_HOME/.cache/antidote $home/.cache/antidote &&
    ln -s $ZT_REAL_HOME/.cache/gitstatus $home/.cache/gitstatus &&
    ln -s $ZT_REAL_HOME/.local/opt $home/.local/opt || return 1
  print -r -- "LAST_EPOCH=$(( EPOCHSECONDS / 86400 ))" >$home/.cache/zsh/.zsh-update
}

# zt_env <home> <tmpdir>: sets reply to the environment a scratch boot starts from
zt_env() {
  reply=(
    HOME=$1 USER=$USER LOGNAME=$USER SHELL=/bin/zsh LANG=${LANG:-en_US.UTF-8}
    PATH=/usr/bin:/bin:/usr/sbin:/sbin TMPDIR=$2/
    MERCURY_API_KEY=dummy ANTHROPIC_API_KEY=dummy
    MISE_DATA_DIR=$ZT_REAL_HOME/.local/share/mise MISE_CONFIG_DIR=$ZT_REAL_HOME/.config/mise
    MISE_STATE_DIR=$ZT_REAL_HOME/.local/state/mise MISE_CACHE_DIR=$ZT_REAL_HOME/Library/Caches/mise
    MISE_NOT_FOUND_AUTO_INSTALL=false MISE_EXEC_AUTO_INSTALL=false MISE_TASK_RUN_AUTO_INSTALL=false
  )
}

# zt_rex <dir> <args>: the rex CLI on the private server zt_boot started in <dir>, never the real one
zt_rex() {
  "$ZT_REX" --autostart=false -S unix://$1/rex.sock "${@[2,-1]}"
}

# zt_server <home> <dir>: starts a private Rex server in <dir>, whose panes start from the scratch
# environment of <home> (zt_env), with the TMPDIR its boots share (<home>/../tmp)
zt_server() {
  local home=$1 dir=$2 tmp=${1:h}/tmp
  mkdir -p $dir $tmp || return 1
  if [[ ! -x $ZT_REX ]]; then
    print -u2 -r -- 'zt_server: no rex on PATH to host the shells'
    return 1
  fi
  zt_env $home $tmp
  # Its panes start from the server's environment. No config and no saved sessions, so the server
  # holds this boot alone
  env -i $reply "$ZT_REX" server run --listen unix://$dir/rex.sock --state-dir $dir/rex \
    --restore=false --config /dev/null &>$dir/rex.log &!
  print -r -- $! >$dir/rex.pid
  repeat 50; do
    [[ -S $dir/rex.sock ]] && break
    sleep 0.1
  done
}

# zt_boot <home> <dir> <tree>: boots the config laid out in <home> (by zt_home from <tree>) in a
# pane of a private Rex server, first as a top-level login shell (SHLVL 1), then as a login shell
# started from it, and waits for each one's dump (dump.zsh) in <dir>/dump-1.txt and dump-2.txt.
# Boots of one HOME share its TMPDIR (<home>/../tmp), so a second boot is warm, as on a real machine.
# With ZT_PROBE set to a file, each shell also sources it then, writing to <dir>/probe-<SHLVL>.txt
zt_boot() {
  local home=$1 dir=$2 tree=$3
  zt_server $home $dir || return 1
  # --shell=none starts the arguments as they are: through a shell, a zsh would read the config
  # once more. Without the pane's ids, which differ from boot to boot, in the dump's exports
  zt_rex $dir new boot --shell=none --cwd $home -- \
    env -u REX_SESSION -u REX_BLOCK SHLVL=0 ZDOTDIR=$ZT_LIB/zdotdir ZT_DUMP_DIR=$dir ZT_TREE=$tree \
    ${ZT_PROBE:+ZT_PROBE=$ZT_PROBE} /bin/zsh -l >/dev/null ||
    return 1
  zt_await $dir dump-1.txt || return 1
  zt_rex $dir send -s boot 'zsh -l'
  zt_await $dir dump-2.txt || return 1
  kill "$(<$dir/rex.pid)"
}

# zt_await <dir> <file>: presses Enter in the pane every tenth of a second until <dir>/<file>
# appears, since the dump runs at the first prompt after the deferred plugins have loaded
zt_await() {
  local dir=$1 file=$2
  repeat 300; do
    [[ -s $dir/$file ]] && return 0
    if ! zt_rex $dir send-key -s boot enter 2>/dev/null; then
      print -u2 -r -- "zt_await: the server is gone, with no $file yet"
      return 1
    fi
    sleep 0.1
  done
  print -u2 -r -- "zt_await: no $file after 30s, the pane shows:"
  zt_rex $dir capture -s boot --trim 2>/dev/null | grep -v '^$' >&2
  return 1
}
