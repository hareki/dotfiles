# build against stand-ins for the toolchains: cargo, go, brew, make and autogen.sh log their call
# in place of a build, and rustc and du answer with what a scenario sets. Each target gets a bare
# repo (remote/<target>.git) as its origin and its checkout in $REPOS_DIR, and HOME is a scratch
# dir, so the install root and its stamps are too

source "$ZT_LIB/helpers.zsh"
source "$ZT_LIB/repos.zsh"
zmodload zsh/zselect

# Globals are named apart from build's locals (root, target, targets), which shadow them for the
# stand-ins it calls
zt_repos
top=$ZT_TMP
export HOMEBREW_PREFIX=$top/brew
mkdir -p $top/gate

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

# cargo makes the target dir it builds in, and clean removes it. Its metadata holds the workspace's
# packages, or nothing once a scenario sets $unreadable
cargo() {
  if [[ $1 == metadata ]]; then
    [[ -z $unreadable ]] || return 1
    print -r -- '{"packages": [
      {"name": "atuin-client", "features": {"default": ["sync", "daemon"]}},
      {"name": "atuin", "features": {"default": ["client", "ai", "daemon", "sync", "octavo", "pty-proxy", "clipboard"], "ai": ["atuin-ai"]}}
    ]}'
  elif [[ $1 == install ]]; then
    mkdir -p target
    compile cargo "$@" "(root ${CARGO_INSTALL_ROOT/#$HOME/~}${CARGO_PROFILE_RELEASE_LTO:+, $CARGO_PROFILE_RELEASE_LTO LTO over $CARGO_PROFILE_RELEASE_CODEGEN_UNITS units})"
  else
    call cargo "$@"
    [[ $1 != clean ]] || rm -rf target
  fi
}
# The rustc in use, and the size of a checkout's target dir where a scenario sets one
rustc_version=1.0.0
typeset -A kilobytes
rustc() {
  print -r -- "rustc $rustc_version"
}
du() {
  print -r -- "${kilobytes[${PWD:t}]:-1024}"$'\t'"target"
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
  if [[ $1 == -j* ]]; then
    compile make "$@"
  else
    call make "$@"
  fi
}
_evalcache_clear() {
  call _evalcache_clear
}

# recipe <target> [scratch]: the calls of its build, with scratch from an emptied target dir
recipe() {
  [[ $2 != scratch ]] || print -r -- "$1 cargo clean"
  case $1 in
    atuin)
      [[ -n $unreadable ]] || local trimmed=' --no-default-features --features=client,sync,clipboard'
      print -r -- "$1 cargo install --locked --path crates/atuin$trimmed (root ~/.local/opt)"
      ;;
    eza|television) print -r -- "$1 cargo install --locked --path . (root ~/.local/opt, thin LTO over 16 units)" ;;
    worktrunk) print -r -- "$1 cargo install --locked --path . (root ~/.local/opt)" ;;
    lazygit|fzf) print -r -- "$1 go install (GOBIN ~/.local/opt/bin)" ;;
    tmux)
      print -rl -- "$1 brew install libevent utf8proc jemalloc" "$1 sh autogen.sh" \
        "$1 ./configure --prefix=$HOME/.local/opt --enable-utf8proc --enable-jemalloc" \
        "$1 make clean" "$1 make -j$(sysctl -n hw.ncpu)" "$1 make install" "$1 make distclean"
      ;;
  esac
  print -r -- "$1 _evalcache_clear"
}

# --- Scratch repos and brew libraries

# push_commit <target> <subject>: a commit of src.txt, holding just <subject>, on the target's origin
push_commit() {
  zt_commit $top/work/$1 $2 src.txt $2 && git -C $top/work/$1 push -q origin HEAD:main
}

# brew_lib <lib> <version>: the library as brew links it, opt/<lib> => Cellar/<lib>/<version>
brew_lib() {
  mkdir -p $HOMEBREW_PREFIX/{opt,Cellar/$1/$2} && ln -sfn ../Cellar/$1/$2 $HOMEBREW_PREFIX/opt/$1
}

for name in $names; do
  git init -q $top/work/$name &&
    zt_commit $top/work/$name c1 src.txt c1 &&
    git clone -q --bare $top/work/$name $top/remote/$name.git &&
    git -C $top/work/$name remote add origin $top/remote/$name.git &&
    git clone -q $top/remote/$name.git $REPOS_DIR/$name || exit 1
done
for lib in libevent utf8proc jemalloc; do
  brew_lib $lib 1.0
done

# --- Checks

# run <builds> <build args>: build, with <builds> builds due to run side by side: stdout and stderr
# into out and err, the exit status into rc
run() {
  together=$1
  rm -f $top/gate/*(N)
  : >$calls
  build "${@[2,-1]}" >$top/out 2>$top/err
  rc=$?
}

# plain <file>: the output without SGR escapes, and with a build's duration masked
plain() {
  setopt local_options extended_glob
  local text=$(t_plain $1)
  print -r -- "${text//(#b)(built in|failed after) [0-9ms ]##/$match[1] <t>}"
}

# build_all <what> <exit status> [<target>=<state>...]: runs `build all`, with the builds its
# states make due side by side, and checks it. Its report is the header, then the lines of each
# state, sorted as the jobs report in any order, and its calls are the recipe of every target that
# built. A target without a state is current:
#   current   up to date, nothing ran
#   built     built
#   scratch   built, cargo's target dir emptied first
#   broken    pulled, but the build failed in its long step
#   unpulled  the pull failed, nothing ran
build_all() {
  local what=$1 want_rc=$2 pair name
  local -a lines want_calls out
  local -A want
  local -i due=0
  for pair in "${@[3,-1]}"; do
    want[${pair%%=*}]=${pair#*=}
  done
  for name in $names; do
    case ${want[$name]:-current} in
      current)  lines+=("$name: up to date") ;;
      built|scratch)
        (( due++ ))
        lines+=("$name: building" "$name: built in <t>")
        want_calls+=("${(@f)$(recipe $name $want[$name])}")
        ;;
      broken)
        (( due++ ))
        lines+=("$name: building" "$name: failed after <t>")
        want_calls+=("${${(f)$(recipe $name)}[1]}" "$name _evalcache_clear")
        ;;
      unpulled) lines+=("$name: failed after <t>") ;;
    esac
  done
  run $due all
  out=("${(@f)$(plain $top/out)}")
  t_eq "$what: exit status" $rc $want_rc
  t_lines "$what: a line per target" "$(print -rl -- "${(@)out[1,2]}" ${(o)out[3,-1]})" \
    "$(print -rl -- '' '======== Building all targets ========' ${(o)lines})"
  # A stable sort, so each target's calls stay in the order it made them
  t_lines "$what: the calls of each build" "$(sort -s -k1,1 $calls)" "$(print -rl -- $want_calls | sort -s -k1,1)"
}

# --- `build all`

build_all 'first run' 0 {atuin,eza,television,worktrunk}=scratch {lazygit,fzf,tmux}=built
t_eq 'first run: no stderr' "$(<$top/err)" ''
t_match 'first run: the logs are in a dir of their own in TMPDIR' "$(<$top/logdirs)" "$TMPDIR/build.??????"
t_eq 'first run: Ctrl-C reaches a build' "$(<$top/traps)" ''

build_all 'nothing new' 0

# One change per target, atuin none:
# - eza: a commit on origin
# - fzf: a reworded commit with the same tree, its checkout moved along as sync-forks moves one
# - television: an uncommitted change
# - worktrunk: a commit on origin that doesn't compile
# - lazygit: an origin that's gone
# - tmux: one of its brew libraries upgraded
push_commit eza c2
git -C $top/work/fzf commit -q --amend -m reworded && git -C $top/work/fzf push -q --force origin HEAD:main
git -C $REPOS_DIR/fzf fetch -q && git -C $REPOS_DIR/fzf reset -q --hard origin/main
print local >>$REPOS_DIR/television/src.txt
push_commit worktrunk c2
broken=(worktrunk)
git -C $REPOS_DIR/lazygit remote set-url origin $top/remote/gone.git
brew_lib libevent 2.0

build_all 'changes' 1 eza=built fzf=current television=built worktrunk=broken lazygit=unpulled tmux=built
err=$(plain $top/err)
t_match 'changes: stderr has the log of the failed build' "$err" \
  '*==> Failed to build worktrunk:*Fast-forward*worktrunk: compile error*'
t_match 'changes: stderr has the log of the failed pull' "$err" \
  '*==> Failed to build lazygit:*does not appear to be a git repository*'
headers=(${(M)${(f)err}:#'==> '*})
t_eq 'changes: stderr has no other log' $#headers 2

# A failed build and an uncommitted change are built again, a build that succeeded is not
build_all 'same changes again' 1 television=built worktrunk=broken lazygit=unpulled

# Fixed, the failed ones catch up, and the checkout with its change gone is built once more, as
# what's installed still has the change
broken=()
git -C $REPOS_DIR/lazygit remote set-url origin $top/remote/lazygit.git
git -C $REPOS_DIR/television checkout -q -- src.txt
build_all 'changes fixed' 0 television=built worktrunk=built
t_eq 'changes fixed: no stderr' "$(<$top/err)" ''

build_all 'settled' 0
t_eq 'no log dir outlives a run' "$(print -rl -- $TMPDIR/*(N))" ''

# --- cargo's target dirs

# Kept from build to build since each target's first, until one has grown past 4GB
push_commit television c2
push_commit worktrunk c3
kilobytes[worktrunk]=$(( 5 * 1024 ** 2 ))
build_all 'a target dir past 4GB' 0 television=built worktrunk=scratch
kilobytes=()

# ...or rustc is a new one, which the dir is then kept for
rustc_version=1.1.0
push_commit eza c3
build_all 'a new rustc' 0 eza=scratch
push_commit eza c4
build_all 'the same rustc again' 0 eza=built

# --- `build <target>`

# Builds whatever the checkout holds, every time (the first from scratch, on its first build since
# the new rustc), and `build all` then finds it up to date
push_commit atuin c2
git -C $REPOS_DIR/atuin pull -q
cd $REPOS_DIR/atuin
run 1 atuin
t_lines 'build <target>: builds the checkout' "$rc $(<$calls)" "0 $(recipe atuin scratch)"
run 1 atuin
t_lines 'build <target>: builds it again' "$rc $(<$calls)" "0 $(recipe atuin)"
cd $top
build_all 'build <target>: up to date for build all' 0

# atuin builds with every default feature when its manifest can't tell which there are
unreadable=1
cd $REPOS_DIR/atuin
run 1 atuin
t_lines 'build atuin: all features without a readable manifest' "$rc $(<$calls)" "0 $(recipe atuin)"
unreadable=
cd $top

# ...unless it built uncommitted changes, or failed
print local >>$REPOS_DIR/atuin/src.txt
cd $REPOS_DIR/atuin
run 1 atuin
git checkout -q -- src.txt
broken=(eza)
cd $REPOS_DIR/eza
run 1 eza
t_lines 'build <target>: a failed build' "$rc $(<$calls)"$'\n'"$(<$top/err)" \
  "1 ${$(recipe eza)[(f)1]}"$'\n'"eza _evalcache_clear"$'\n'"eza: compile error"
broken=()
cd $top
build_all 'build <target>: uncommitted changes and a failure leave it due' 0 atuin=built eza=built

# --- The rest of the interface

run 0 nope
t_lines 'an unknown target' "$rc"$'\n'"$(<$top/err)"$'\n'"$(<$top/out)" "\
1
Unknown target: nope
Usage: build <target>
Available targets: all, atuin, eza, television, worktrunk, lazygit, fzf, tmux"
t_eq 'an unknown target: nothing ran' "$(<$calls)" ''

t_done
