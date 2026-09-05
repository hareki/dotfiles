#!/bin/sh
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
#
# lazygit starts this script again for every diff it draws, so the transport is
# paid on every keypress that moves the selection -- and a small diff renders in
# well under a millisecond, which makes the client the whole cost. The request
# therefore goes over the daemon's plain line socket with `nc` (~4ms round
# trip); an `nvim --remote-expr` client, ~36ms of startup before it says a word,
# is only the fallback for a machine without nc or a daemon that predates it.
#
# noclobber: the render's output path is derived from the input path rather than
# made by a second mktemp, so every open that creates it must refuse a name
# somebody else planted (see write_output in daemon.lua). `>|` opts back out
# where the target is a file we already own.
set -Cu

# $TMPDIR is trailing-slash-terminated on macOS but bare on most other systems.
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
SOCK="$TMP/lazygit-codediff-${USER:-u}.sock"
PIPE="$TMP/lazygit-codediff-${USER:-u}.pipe"

IN=$(mktemp "$TMP/codediff-in.XXXXXX" 2>/dev/null) || exec cat
OUT="$IN.out"
trap 'rm -f "$IN" "$OUT"' EXIT

cat >|"$IN"
COLS="${LAZYGIT_COLUMNS:-120}"

# Optional --layout=<inline|side-by-side> from the diffRenderers command
# string; anything unrecognized renders inline.
LAYOUT="inline"
for a in "$@"; do
  case "$a" in
    --layout=*) LAYOUT="${a#--layout=}" ;;
  esac
done

# The daemon ties its lifetime to the lazygit process that owns this render, but
# one live owner is all it needs: it asks for one (an `ok:owner` answer) only
# while it is watching none, which is once per lazygit session rather than once
# per render. One ps per level: it reports the parent and the command name
# together, and shell word-splitting separates them.
OWNER=""
owner_walked=0
find_owner() {
  [ "$owner_walked" = 0 ] || return 0
  owner_walked=1
  pid=$$
  for _ in 1 2 3 4 5 6 7; do
    # shellcheck disable=SC2046 # deliberate word-splitting into ppid + comm
    set -- $(ps -o ppid=,comm= -p "$pid" 2>/dev/null)
    [ $# -ge 2 ] || break
    parent=$1
    shift
    case "$*" in
      *lazygit*) OWNER=$pid; break ;;
    esac
    [ "$parent" -gt 1 ] 2>/dev/null || break
    pid=$parent
  done
}

# One line in, one line back. cwd goes last because it is the only field that
# can legitimately contain a tab.
reply=""
request_pipe() {
  reply=$(printf 'render\t%s\t%s\t%s\t%s\t%s\n' "$IN" "$OUT" "$COLS" "$LAYOUT" "$PWD" | nc -U "$PIPE" 2>/dev/null)
  case "$reply" in
    ok | ok:owner) return 0 ;;
    *) return 1 ;;
  esac
}

# Deliberately after the rendered bytes are on their way out: registering an
# owner costs a process tree walk, and nothing about this render depends on it.
register_owner() {
  [ "$reply" = "ok:owner" ] || return 0
  find_owner
  [ -n "$OWNER" ] || return 0
  printf 'owner\t%s\n' "$OWNER" | nc -U "$PIPE" >/dev/null 2>&1
}

# Single quotes in a vimscript string literal are escaped by doubling. The
# arguments are two temp paths, $PWD, a column count and a layout name, so the
# quote is essentially never there and the common case stays fork-free.
esc() {
  case $1 in
    *\'*) printf %s "$1" | sed "s/'/''/g" ;;
    *) printf %s "$1" ;;
  esac
}

res=""
request_rpc() {
  find_owner
  res=$(nvim --clean --server "$SOCK" --remote-expr \
    "v:lua.CODEDIFF.render('$(esc "$IN")','$(esc "$OUT")','$(esc "$PWD")','$(esc "$COLS")','$OWNER','$(esc "$LAYOUT")')" \
    2>/dev/null) && [ "$res" = "ok" ]
}

# The -S tests keep a cold start from paying for a connection attempt to a
# socket that is not there -- for the RPC client that alone is a full nvim
# startup, spent only to rediscover there is nothing to connect to.
if [ -S "$PIPE" ] && request_pipe; then
  cat "$OUT"
  register_owner
  exit 0
fi

if [ -S "$SOCK" ] && request_rpc; then
  cat "$OUT"
  exit 0
fi

# The render failed. Everything from here down is a cold path, and only these
# paths need the script's own directory.
DIR=$(cd "$(dirname "$0")" && pwd)

# Only replace the sockets when nothing is listening on them: unlinking a live
# daemon's socket orphans it (it keeps running, unreachable, until its idle
# timeout) and races a concurrent client that just spawned one. An empty answer
# from both transports is what "nothing is listening" looks like -- a daemon
# that answered anything at all is alive, and this render simply failed. The
# spawner puts the daemon in its own session; anything attached to lazygit's
# render pty would be SIGHUP'd when the pty closes after this render.
if [ -z "$reply" ] && [ -z "$res" ]; then
  rm -f "$PIPE" "$SOCK"
  # A failed spawn (uv.spawn returned nothing; the spawner exits 1) can never
  # produce a socket: skip the wait loop and the doomed request, so a broken
  # nvim binary or fork pressure costs nothing extra on every render.
  if nvim --clean -l "$DIR/spawn_daemon.lua" "$SOCK" >/dev/null 2>&1; then
    # The pipe is bound once the daemon has bootstrapped its parsers, so its
    # arrival is also the signal that a render will be answered rather than
    # queued behind a second of startup.
    i=0
    while [ $i -lt 40 ] && [ ! -e "$PIPE" ]; do
      sleep 0.05
      i=$((i + 1))
    done
    if request_pipe; then
      cat "$OUT"
      register_owner
      exit 0
    fi
    if request_rpc; then
      cat "$OUT"
      exit 0
    fi
  fi
fi

# Last resort. Written to a file rather than piped, because nvim can die (parser
# crash, OOM, a signal) with part of the render already on stdout: appending the
# raw diff to a half-written one would show the hunks twice.
rm -f "$OUT"
if CODEDIFF_LAYOUT="$LAYOUT" nvim --clean -l "$DIR/render.lua" <"$IN" >"$OUT" 2>/dev/null; then
  cat "$OUT"
else
  cat "$IN"
fi
exit 0
