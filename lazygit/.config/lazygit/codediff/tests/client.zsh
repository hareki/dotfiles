#!/bin/zsh -f
# The client's ladder (client.sh), rung by rung, and one daemon's life.
#
#   tests/client.zsh
#
# The client is run the way lazygit runs it: by the names config.yml has for it, git's output on
# stdin. Which rung it lands on is decided from outside, by what stands at the socket and by
# which nvim PATH finds, so most rungs meet a stand-in: a listener that takes one request, an
# nvim that only notes what it was started for. The real renderer and a real daemon come last.
#
# What keeps a test daemon apart from the user's live one:
#
#   TMPDIR is private and short   the socket lives in it, and a path past ~104 bytes won't bind
#   pgrep is a stub               a daemon stays while any lazygit runs, the user's included
#   the tree is a copy            a daemon recycles itself when its sources change, so touching
#                                 the copy is also how a test daemon is told to go
#
# Takes ~6s. The daemon that is left to idle runs on a shorter grace and poll than daemon.lua's
# 10s and 3s, set in the copy: what is under test is that an idle daemon goes, not how long 10s is.

zmodload zsh/net/socket zsh/datetime

# As the client does before it starts one: mise's shim only falls through to nvim, at ~65ms
path=(${path:#*/mise/shims})

TESTS=${0:A:h}
CODEDIFF=$TESTS:h
REPO=$CODEDIFF:h:h:h:h
CONFIG=$CODEDIFF:h/config.yml
SHIMS=$REPO/bin/.local/bin/shims
FIXTURES=$TESTS/fixtures

# The real path: the client finds its tree through its link, and names it that way
ROOT=${$(mktemp -d /tmp/codediff-test.XXXXXX):A}
TMP=$ROOT/t
PIPE=$TMP/lazygit-codediff-${USER:-u}.pipe
export FAKE_LOG=$ROOT/nvim.log
mkdir $TMP $ROOT/{bin,stub,fake,logged,tree,cwd}

typeset -i failed=0

ok() {
  print -r -- "ok      $1"
}

fail() {
  failed=1
  print -r -- "FAILED  $1"
  [[ -n ${2-} ]] && print -r -- "  ${2//$'\n'/$'\n'  }"
  return 0
}

# check <name> <command...>: passes when the command does
check() {
  local name=$1
  shift
  if "$@"; then ok $name; else fail $name "failed: ${(j: :)${(q-)@}}"; fi
}

# same <name> <actual file> <expected file>
same() {
  if cmp -s $2 $3; then ok $1; else fail $1 "$(cmp $2 $3 2>&1)"; fi
}

# equal <name> <actual> <expected>
equal() {
  if [[ $2 == $3 ]]; then ok $1; else fail $1 "expected ${(qqq)3}"$'\n'"actual   ${(qqq)2}"; fi
}

# wait_until <seconds> <command...>: whether the command passed within that long
wait_until() {
  local -F deadline=$(( EPOCHREALTIME + $1 ))
  shift
  until "$@"; do
    (( EPOCHREALTIME < deadline )) || return 1
    sleep 0.01
  done
}

listening() { [[ -S $PIPE ]] }
not_listening() { [[ ! -e $PIPE ]] }
work_dirs() { print -r -- $TMP/codediff.*(N) }

# client <name> [VAR=value...]: the client by one of its names, in the private namespace
IN_NAMESPACE=(env -u OSC1717 TMPDIR=$TMP/ PATH=$ROOT/stub:$PATH COLUMNS=100)
client() {
  local name=$1
  shift
  $IN_NAMESPACE "$@" $ROOT/bin/$name
}

# A daemon told to go: its sources look changed, and it leaves once it has answered. Without
# this one outlives the test, unreachable, for as long as the user's lazygit runs.
stop_daemon() {
  listening || return 0
  touch $ROOT/tree/lib/util.lua
  client $NAMES[1] <<<'' >/dev/null
  wait_until 5 not_listening
}

cleanup() {
  # A daemon that would not go when told is ended by hand: only it holds this socket
  stop_daemon || kill $(lsof -t $PIPE) 2>/dev/null
  rm -rf $ROOT
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

# ----------------------------------------------------------------- stand-ins ---

cat >$ROOT/stub/pgrep <<'EOF'
#!/bin/sh
# No lazygit runs, as far as a test daemon can tell.
exit 1
EOF

# nvim, as far as the client can tell: it notes what it was started for, never starts a daemon,
# and renders one-shot only when FAKE_NVIM says so, by naming what it was asked for.
cat >$ROOT/fake/nvim <<'EOF'
#!/bin/sh
echo "$*" >>"$FAKE_LOG"
case "$*" in
  *render.lua*)
    [ "$FAKE_NVIM" = renders ] || exit 1
    echo "one-shot layout=$CODEDIFF_LAYOUT metadata=$CODEDIFF_METADATA"
    cat
    ;;
  *) exit 1 ;;
esac
EOF

# The real nvim, noting what it was started for: which rung served a request shows in what the
# client had to start.
cat >$ROOT/logged/nvim <<EOF
#!/bin/sh
echo "\$*" >>"\$FAKE_LOG"
exec ${(q)commands[nvim]} "\$@"
EOF

chmod +x $ROOT/stub/pgrep $ROOT/fake/nvim $ROOT/logged/nvim
FAKE_PATH=$ROOT/fake:$ROOT/stub:$PATH
LOGGED_PATH=$ROOT/logged:$ROOT/stub:$PATH

# listen <answer> [payload]: the daemon, for one request. Keeps the request's line and input,
# puts the payload in the output file the line names when the answer is ok, and answers.
listen() {
  local answer=$1 payload=${2-} line listener connection
  local -a fields
  zsocket -l $PIPE || return
  listener=$REPLY
  : >$ROOT/listening
  zsocket -a $listener || return
  connection=$REPLY
  IFS= read -r -u $connection line
  print -r -- $line >$ROOT/request
  fields=("${(@ps:\t:)line}")
  cp $fields[1] $ROOT/request.in
  [[ -f $fields[2] ]] && : >$ROOT/request.out-was-there
  [[ $answer == ok ]] && print -rn -- $payload >$fields[2]
  print -r -u $connection -- $answer
  exec {connection}>&- {listener}>&-
}

# with_listener <answer> <payload> <command...>: run the command against a stand-in daemon
with_listener() {
  local answer=$1 payload=$2 pid
  shift 2
  rm -f $PIPE $ROOT/listening $ROOT/request*(N)
  listen $answer $payload &
  pid=$!
  wait_until 5 test -e $ROOT/listening
  "$@"
  kill $pid 2>/dev/null
  wait $pid 2>/dev/null
}

# ------------------------------------------------------------------ the names ---

# The names config.yml runs its diff renderers by are the links in the shims directory, and the
# tests run a copy of the tree by the same names.
NAMES=(${(f)"$(sed -n '/^  diffRenderers:/,/^[^ #]/s/^ *command: //p' $CONFIG)"})
equal 'config.yml names two renderers' "$NAMES" 'lazygit-codediff lazygit-codediff-split'
cp -R $CODEDIFF/{client.sh,daemon.lua,render.lua,spawn_daemon.lua,lib} $ROOT/tree/
for name in $NAMES; do
  check "$name is a link to the client" test $SHIMS/$name -ef $CODEDIFF/client.sh
  ln -s $ROOT/tree/client.sh $ROOT/bin/$name
done
typeset -A LAYOUT=(lazygit-codediff inline lazygit-codediff-split side-by-side)

HANDSHAKE=$'\e]1717;1\a'
# The width a client sends: its shell's COLUMNS, which is the terminal's when one is in reach,
# as it is for this shell, and the variable lazygit exports otherwise. A real render is compared
# at that width.
if { : </dev/tty } 2>/dev/null; then COLS=$COLUMNS; else COLS=100; fi
DIFF=$FIXTURES/lua-small.diff
# More than the one chunk a client reads before it decides where its input goes
LONG=$ROOT/long.diff
repeat 8 cat $FIXTURES/commit-go-md.diff >>$LONG
GRAPH=$ROOT/graph
cat >$GRAPH <<'EOF'
* 1a2b3c4 (HEAD -> main) Tidy up
| * 5d6e7f8 A side branch
|/
* 9a0b1c2 Start
EOF

cd $ROOT/cwd

# ------------------------------------------------------- rungs with stand-ins ---

: >$FAKE_LOG
client $NAMES[1] PATH=$FAKE_PATH <$GRAPH >$ROOT/out
same 'a graph goes straight through' $ROOT/out $GRAPH
equal 'a graph starts no nvim' "$(<$FAKE_LOG)" ''
check 'a graph leaves no socket' not_listening
equal 'a graph makes no work directory' "$(work_dirs)" ''

client $NAMES[1] TMPDIR=$ROOT/missing/ PATH=$FAKE_PATH <$DIFF >$ROOT/out
same 'with nowhere to buffer it, a diff goes through as git wrote it' $ROOT/out $DIFF

for offer in V1 'V2,V1' 'V1 V2'; do
  client $NAMES[1] OSC1717=$offer <$GRAPH >$ROOT/out
  print -rn -- $HANDSHAKE | cat - $GRAPH >$ROOT/expected
  same "the handshake comes first when lazygit offers $offer" $ROOT/out $ROOT/expected
done
client $NAMES[1] OSC1717=V2,V10 <$GRAPH >$ROOT/out
same 'no handshake when lazygit offers only other versions' $ROOT/out $GRAPH

# A directory with a tab in its name: cwd is the one field that may hold one
mkdir $ROOT/$'a\tdir'
cd $ROOT/$'a\tdir'
# The second name is run the way lazygit runs one when it can read records
typeset -A OFFER=($NAMES[1] '' $NAMES[2] OSC1717=V1) METADATA=($NAMES[1] 0 $NAMES[2] 1)
for name in $NAMES; do
  metadata=$METADATA[$name]
  with_listener ok 'RENDERED' eval 'client $name $=OFFER[$name] <$LONG >$ROOT/out'
  fields=("${(@ps:\t:)$(<$ROOT/request)}")

  print -rn -- "${OFFER[$name]:+$HANDSHAKE}RENDERED" >$ROOT/expected
  same "$name prints what the daemon put in the output file" $ROOT/out $ROOT/expected
  same "$name: the input is whole by the time the request is sent" $ROOT/request.in $LONG
  check "$name: the output file is there before the request" test -e $ROOT/request.out-was-there
  equal "$name asks for its layout" $fields[4] $LAYOUT[$name]
  equal "$name asks for records only when lazygit offered them" $fields[5] $metadata
  equal "$name: the directory closes the line, tab and all" "${(pj:\t:)fields[6,-1]}" $PWD
  equal "$name sends the width its shell sees" $fields[3] $COLS
  equal "$name removes its work directory" "$(work_dirs)" ''
done
cd $ROOT/cwd

: >$FAKE_LOG
with_listener err '' eval 'client $NAMES[1] PATH=$FAKE_PATH FAKE_NVIM=renders <$DIFF >$ROOT/out'
{ print 'one-shot layout=inline metadata=0'; cat $DIFF } >$ROOT/expected
same 'a daemon that answers err leaves the render to a one-shot' $ROOT/out $ROOT/expected
check 'a daemon that answers err keeps its socket' listening
equal 'a daemon that answers err is not replaced' "$(<$FAKE_LOG)" "--clean -l $ROOT/tree/render.lua"
rm -f $PIPE

: >$FAKE_LOG
client $NAMES[2] PATH=$FAKE_PATH FAKE_NVIM=renders OSC1717=V1 <$DIFF >$ROOT/out
{
  print -n -- $HANDSHAKE
  print 'one-shot layout=side-by-side metadata=1'
  cat $DIFF
} >$ROOT/expected
same 'with no daemon to be had, a one-shot is told the layout and records' \
  $ROOT/out $ROOT/expected
equal 'the one-shot comes after an attempt to start a daemon' "$(<$FAKE_LOG)" \
  "--clean -l $ROOT/tree/spawn_daemon.lua"$'\n'"--clean -l $ROOT/tree/render.lua"

client $NAMES[1] PATH=$FAKE_PATH FAKE_NVIM=broken <$DIFF >$ROOT/out
same 'when nothing can render, the diff comes back as git wrote it' $ROOT/out $DIFF
equal 'no rung leaves a work directory' "$(work_dirs)" ''

# A client lazygit ends mid-read: git's side of the pipe closes with it
mkfifo $ROOT/fifo
# Not through client(): the signal has to reach the client itself
$IN_NAMESPACE PATH=$FAKE_PATH $ROOT/bin/$NAMES[1] <$ROOT/fifo >/dev/null &
pid=$!
exec {git}>$ROOT/fifo
print -r -u $git -- 'diff --git a/x b/x'
check 'a client buffers its input in a work directory' wait_until 5 eval '[[ -n $(work_dirs) ]]'
kill -TERM $pid
exec {git}>&-
wait $pid
equal 'a client that was ended leaves no work directory' "$(work_dirs)" ''

# ---------------------------------------------------------- the real renderer ---

# oneshot <layout> <metadata>: what render.lua makes of stdin, at the client's width
oneshot() {
  env -u OSC1717 COLUMNS=$COLS CODEDIFF_LAYOUT=$1 CODEDIFF_METADATA=$2 \
    nvim --clean -l $ROOT/tree/render.lua
}

(
  cd /
  COLS=100
  oneshot inline 0 <$DIFF >$ROOT/out
  same 'a one-shot render is the golden (inline)' $ROOT/out $FIXTURES/lua-small.out
  oneshot side-by-side 0 <$DIFF >$ROOT/out
  same 'a one-shot render is the golden (side-by-side)' $ROOT/out $FIXTURES/lua-small.split.out
  exit $failed
) || failed=1

SPAWNED="--clean -l $ROOT/tree/spawn_daemon.lua"

: >$FAKE_LOG
oneshot inline 0 <$DIFF >$ROOT/expected
client $NAMES[1] PATH=$LOGGED_PATH <$DIFF >$ROOT/out
same 'with nobody listening, a new daemon renders what a one-shot does' $ROOT/out $ROOT/expected
equal 'the client waited for that daemon and rendered nothing itself' "$(<$FAKE_LOG)" $SPAWNED
check 'the new daemon stays' listening

{ print -n -- $HANDSHAKE; oneshot side-by-side 1 <$DIFF } >$ROOT/expected.split
client $NAMES[2] PATH=$LOGGED_PATH OSC1717=V1 <$DIFF >$ROOT/out
same 'the daemon renders the other layout, with records' $ROOT/out $ROOT/expected.split
client $NAMES[2] PATH=$LOGGED_PATH OSC1717=V1 <$DIFF >$ROOT/out
same 'the same request again gets the same render' $ROOT/out $ROOT/expected.split
equal 'a client served by a running daemon starts no nvim' "$(<$FAKE_LOG)" $SPAWNED

zsocket $PIPE
print -r -u $REPLY -- 'not a request'
read -r -u $REPLY answer
exec {REPLY}>&-
equal 'the daemon answers err to a line that is not a request' $answer err
equal 'a served client leaves no work directory' "$(work_dirs)" ''

# --------------------------------------------------------------- one daemon's life ---

touch $ROOT/tree/lib/util.lua
client $NAMES[1] <$DIFF >$ROOT/out
same 'a daemon whose sources changed still answers the request in hand' $ROOT/out $ROOT/expected
check 'and then goes' wait_until 5 not_listening

# The next daemon is the one left to idle, on a grace and a poll short enough to wait out
sed -i '' \
  -e 's/^local IDLE_WITHOUT_LAZYGIT_MS = .*/local IDLE_WITHOUT_LAZYGIT_MS = 3000/' \
  -e 's/^local POLL_MS = .*/local POLL_MS = 500/' $ROOT/tree/daemon.lua
equal 'the copy of the daemon idles on a short grace and poll' \
  "$(grep -cE '^local (IDLE_WITHOUT_LAZYGIT_MS = 3000|POLL_MS = 500)$' $ROOT/tree/daemon.lua)" 2

client $NAMES[1] PATH=$LOGGED_PATH <$DIFF >$ROOT/out
same 'the next client is served all the same' $ROOT/out $ROOT/expected
equal 'by a daemon it had to start' "$(<$FAKE_LOG)" $SPAWNED$'\n'$SPAWNED
sleep 1
check 'an idle daemon outlives a third of its grace with no lazygit running' listening
check 'and is gone soon after the rest of it' wait_until 5 not_listening

exit $failed
