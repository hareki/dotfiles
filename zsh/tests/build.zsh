# build against stand-ins for the toolchains: cargo, go, brew, make and autogen.sh log their call
# in place of a build. Each target gets a bare repo (remote/<target>.git) as its origin and its
# checkout in $REPOS_DIR, and HOME is a scratch dir, so the install root and its stamps are too

source "$ZT_LIB/helpers.zsh"
zmodload zsh/zselect

# HOME and git's global config move in here. Globals are named apart from build's locals (root,
# target, targets), which shadow them for the stand-ins it calls
[[ $ZT_TMP == /tmp/zt.?* && -d $ZT_TMP ]] || { print -ru2 -- 'ZT_TMP must be a /tmp/zt.* dir'; exit 1 }
top=$ZT_TMP
# A git call missing its -C then fails, instead of reaching the repo the test started in
cd $top

# git reads no config but this one, and reaches nothing but the bare repos here
unset -m 'GIT_*' XDG_CONFIG_HOME
export HOME=$top/home REPOS_DIR=$top/home/repos HOMEBREW_PREFIX=$top/brew
export GIT_CONFIG_GLOBAL=$top/gitconfig GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file
path=(/usr/bin /bin /usr/sbin /sbin)
mkdir -p $REPOS_DIR $top/gate
cat >$GIT_CONFIG_GLOBAL <<EOF
[user]
  name = zt
  email = zt@example.invalid
[init]
  defaultBranch = main
EOF

autoload -Uz $ZT_PKG/.config/zsh/functions/{build,print-header}
names=(${(f)"$(build --list)"})

# --- Stand-ins

# call <words>: the line a stand-in leaves in $calls, "<checkout> <words>"
calls=$top/calls
call() {
  print -r -- "${PWD:t} $*" >>$calls
}

# compile <words>: a toolchain's long step. Logs its call, the log dirs in TMPDIR by then and the
# signals its job ignores, and returns only once $together checkouts have reached theirs, which
# takes builds that run side by side. Fails in a checkout listed in $broken
typeset -i together=1
typeset -a broken
compile() {
  local -a reached
  call "$@"
  : >$top/gate/${PWD:t}
  print -rl -- $TMPDIR/build.*(N/) >$top/logdirs
  trap >$top/traps
  repeat 200; do
    reached=($top/gate/*(N))
    (( $#reached >= together )) && break
    zselect -t 5
  done
  if (( $#reached < together )); then
    print -ru2 -- "${PWD:t}: only $#reached of $together builds ran side by side"
    return 1
  elif (( $broken[(Ie)${PWD:t}] )); then
    print -ru2 -- "${PWD:t}: compile error"
    return 1
  fi
}

cargo() {
  if [[ $1 == install ]]; then
    compile cargo "$@" "(root ${CARGO_INSTALL_ROOT/#$HOME/~})"
  else
    call cargo "$@"
  fi
}
go() {
  compile go "$@" "(GOBIN ${GOBIN/#$HOME/~})"
}
brew() {
  call brew "$@"
}
# autogen.sh writes the configure script, which build removes again
sh() {
  call sh "$@"
  print -rl -- '#!/bin/sh' "echo \"tmux ./configure \$*\" >>$calls" >configure && chmod +x configure
}
make() {
  if (( $# )); then
    call make "$@"
  else
    compile make
  fi
}
_evalcache_clear() {
  call _evalcache_clear
}

# recipe <target>: the calls of its build
recipe() {
  case $1 in
    atuin) print -rl -- "$1 cargo install --locked --path crates/atuin (root ~/.local/opt)" "$1 cargo clean" ;;
    eza|television|worktrunk) print -rl -- "$1 cargo install --locked --path . (root ~/.local/opt)" "$1 cargo clean" ;;
    lazygit|fzf) print -r -- "$1 go install (GOBIN ~/.local/opt/bin)" ;;
    tmux)
      print -rl -- "$1 brew install libevent utf8proc jemalloc" "$1 sh autogen.sh" \
        "$1 ./configure --prefix=$HOME/.local/opt --enable-utf8proc --enable-jemalloc" \
        "$1 make clean" "$1 make" "$1 make install" "$1 make distclean"
      ;;
  esac
  print -r -- "$1 _evalcache_clear"
}

# --- Fixtures

# commit_in <work tree> <subject> <file> <line>: commits <file>, holding just <line>
commit_in() {
  print -r -- $4 >$1/$3
  git -C $1 add $3 && git -C $1 commit -qm $2
}

# push_commit <target> <subject> <file> <line>: the same on the target's origin
push_commit() {
  commit_in $top/work/$1 "${@[2,-1]}" && git -C $top/work/$1 push -q origin HEAD:main
}

# brew_lib <lib> <version>: the library as brew links it, opt/<lib> => Cellar/<lib>/<version>
brew_lib() {
  mkdir -p $HOMEBREW_PREFIX/{opt,Cellar/$1/$2} && ln -sfn ../Cellar/$1/$2 $HOMEBREW_PREFIX/opt/$1
}

for name in $names; do
  git init -q $top/work/$name &&
    commit_in $top/work/$name c1 src.txt c1 &&
    git clone -q --bare $top/work/$name $top/remote/$name.git &&
    git -C $top/work/$name remote add origin $top/remote/$name.git &&
    git clone -q $top/remote/$name.git $REPOS_DIR/$name || exit 1
done
for lib in libevent utf8proc jemalloc; do
  brew_lib $lib 1.0
done

# --- Checks

# run <builds> <build args>: build under an interactive shell's options, with <builds> builds due
# to run side by side: stdout and stderr into out and err, the exit status into rc
run() {
  setopt local_options $T_INTERACTIVE_OPTIONS
  together=$1
  rm -f $top/gate/*(N) $calls
  : >$calls
  build "${@[2,-1]}" >$top/out 2>$top/err
  rc=$?
}

# plain <file>: the output without SGR escapes, and with a build's duration masked
plain() {
  setopt local_options extended_glob
  local text=$(<$1)
  text=${text//$'\e'\[[0-9;]#m}
  print -r -- "${text//(#b)(built in|failed after) [0-9ms ]##/$match[1] <t>}"
}

# check_all <what> <exit status> <target>=<state>...: the `build all` that just ran. Its report is
# the header, then the lines of each state, sorted as the jobs report in any order, and its calls
# are the recipe of every target that built:
#   current   up to date, nothing ran
#   built     built
#   broken    pulled, but the build failed in its long step
#   unpulled  the pull failed, nothing ran
check_all() {
  local what=$1 want_rc=$2 pair name
  local -a lines want_calls out
  for pair in "${@[3,-1]}"; do
    name=${pair%%=*}
    case ${pair#*=} in
      current)  lines+=("$name: up to date") ;;
      built)    lines+=("$name: building" "$name: built in <t>") want_calls+=("${(@f)$(recipe $name)}") ;;
      broken)
        lines+=("$name: building" "$name: failed after <t>")
        want_calls+=("${${(f)$(recipe $name)}[1]}" "$name _evalcache_clear")
        ;;
      unpulled) lines+=("$name: failed after <t>") ;;
    esac
  done
  out=("${(@f)$(plain $top/out)}")
  t_eq "$what: exit status" $rc $want_rc
  t_lines "$what: a line per target" "$(print -rl -- "${(@)out[1,2]}" ${(o)out[3,-1]})" \
    "$(print -rl -- '' '======== Building all targets ========' ${(o)lines})"
  # A stable sort, so each target's calls stay in the order it made them
  t_lines "$what: the calls of each build" "$(sort -s -k1,1 $calls)" "$(print -rl -- $want_calls | sort -s -k1,1)"
}

# --- `build all`

run 7 all
check_all 'first run' 0 {atuin,eza,television,worktrunk,lazygit,fzf,tmux}=built
t_eq 'first run: no stderr' "$(<$top/err)" ''
t_match 'first run: the logs are in a dir of their own in TMPDIR' "$(<$top/logdirs)" "$TMPDIR/build.??????"
t_eq 'first run: Ctrl-C reaches a build' "$(<$top/traps)" ''

run 0 all
check_all 'nothing new' 0 {atuin,eza,television,worktrunk,lazygit,fzf,tmux}=current

# One change per target, atuin none:
# - eza: a commit on origin
# - fzf: a reworded commit with the same tree, its checkout moved along as sync-forks moves one
# - television: an uncommitted change
# - worktrunk: a commit on origin that doesn't compile
# - lazygit: an origin that's gone
# - tmux: one of its brew libraries upgraded
push_commit eza c2 src.txt c2
git -C $top/work/fzf commit -q --amend -m reworded && git -C $top/work/fzf push -q --force origin HEAD:main
git -C $REPOS_DIR/fzf fetch -q && git -C $REPOS_DIR/fzf reset -q --hard origin/main
print local >>$REPOS_DIR/television/src.txt
push_commit worktrunk c2 src.txt c2
broken=(worktrunk)
git -C $REPOS_DIR/lazygit remote set-url origin $top/remote/gone.git
brew_lib libevent 2.0

run 4 all
check_all 'changes' 1 atuin=current eza=built fzf=current television=built worktrunk=broken lazygit=unpulled tmux=built
err=$(plain $top/err)
t_match 'changes: stderr has the log of the failed build' "$err" \
  '*==> Failed to build worktrunk:*Fast-forward*worktrunk: compile error*'
t_match 'changes: stderr has the log of the failed pull' "$err" \
  '*==> Failed to build lazygit:*does not appear to be a git repository*'
headers=(${(M)${(f)err}:#'==> '*})
t_eq 'changes: stderr has no other log' $#headers 2

# A failed build and an uncommitted change are built again, a build that succeeded is not
run 2 all
check_all 'same changes again' 1 atuin=current eza=current fzf=current television=built worktrunk=broken lazygit=unpulled tmux=current

# Fixed, the failed ones catch up, and the checkout with its change gone is built once more, as
# what's installed still has the change
broken=()
git -C $REPOS_DIR/lazygit remote set-url origin $top/remote/lazygit.git
git -C $REPOS_DIR/television checkout -q -- src.txt
run 2 all
check_all 'changes fixed' 0 atuin=current eza=current fzf=current television=built worktrunk=built lazygit=current tmux=current
t_eq 'changes fixed: no stderr' "$(<$top/err)" ''

run 0 all
check_all 'settled' 0 {atuin,eza,television,worktrunk,lazygit,fzf,tmux}=current
t_eq 'no log dir outlives a run' "$(print -rl -- $TMPDIR/*(N))" ''

# --- `build <target>`

# Builds whatever the checkout holds, every time, and `build all` then finds it up to date
push_commit atuin c2 src.txt c2
git -C $REPOS_DIR/atuin pull -q
cd $REPOS_DIR/atuin
run 1 atuin
t_lines 'build <target>: builds the checkout' "$rc $(<$calls)" "0 $(recipe atuin)"
run 1 atuin
t_lines 'build <target>: builds it again' "$rc $(<$calls)" "0 $(recipe atuin)"
cd $top
run 0 all
check_all 'build <target>: up to date for build all' 0 {atuin,eza,television,worktrunk,lazygit,fzf,tmux}=current

# ...unless it built uncommitted changes, or failed
print local >>$REPOS_DIR/atuin/src.txt
cd $REPOS_DIR/atuin
run 1 atuin
git checkout -q -- src.txt
broken=(eza)
cd $REPOS_DIR/eza
run 1 eza
t_lines 'build <target>: a failed build' "$rc $(<$calls)"$'\n'"$(<$top/err)" \
  "1 eza cargo install --locked --path . (root ~/.local/opt)"$'\n'"eza _evalcache_clear"$'\n'"eza: compile error"
broken=()
cd $top
run 2 all
check_all 'build <target>: uncommitted changes and a failure leave it due' 0 atuin=built eza=built {television,worktrunk,lazygit,fzf,tmux}=current

# --- The rest of the interface

run 0 nope
t_lines 'an unknown target' "$rc"$'\n'"$(<$top/err)"$'\n'"$(<$top/out)" "\
1
Unknown target: nope
Usage: build <target>
Available targets: all, atuin, eza, television, worktrunk, lazygit, fzf, tmux"
t_eq 'an unknown target: nothing ran' "$(<$calls)" ''

t_done
