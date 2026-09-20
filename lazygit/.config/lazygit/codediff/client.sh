#!/bin/sh
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
#
# lazygit starts this script again for every diff it draws, so the transport is
# paid on every keypress that moves the selection -- and a small diff renders in
# well under a millisecond, which makes the client the whole cost. The request
# therefore goes over the daemon's plain line socket with `nc` (~4ms round
# trip), rather than through an `nvim --remote-expr` client that would spend
# ~36ms on startup before it said a word.
#
# noclobber: the render's output path is derived from the input path rather than
# made by a second mktemp, so every open that creates it must refuse a name
# somebody else planted (see write_output in daemon.lua). `>|` opts back out
# where the target is a file we already own.
set -Cu

# $TMPDIR is trailing-slash-terminated on macOS but bare on most other systems.
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
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

# The daemon ties its lifetime to the lazygit processes that own its renders. It
# cannot tell their requests apart, so it asks for the owner (an `ok:owner`
# answer) while it is watching none and otherwise once per interval, which is
# what registers a second lazygit -- rarely either way, never once per render.
# One ps per level: it reports the parent and the command name together, and
# shell word-splitting separates them.
OWNER=""
find_owner() {
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
# lazygit terminates the render task (SIGTERM, then the pty's SIGHUP) as soon as
# the selection moves on, and the answer to a question asked this rarely must not
# be lost to that: the walk takes ~15ms, ignoring both for that long is harmless,
# and answering `0` (nothing found) is what stops the daemon asking again.
register_owner() {
  [ "$reply" = "ok:owner" ] || return 0
  trap '' TERM HUP
  find_owner
  printf 'owner\t%s\n' "${OWNER:-0}" | nc -U "$PIPE" >/dev/null 2>&1
}

# Emit the render and exit if the daemon answers; returns so the caller can fall
# further down the ladder if it did not.
#
# The -S test keeps a cold start from paying for a connection attempt to a
# socket that is not there.
serve() {
  if [ -S "$PIPE" ] && request_pipe; then
    cat "$OUT"
    register_owner
    exit 0
  fi
}

serve

# The render failed. Everything from here down is a cold path, and only these
# paths need the script's own directory.
DIR=$(cd "$(dirname "$0")" && pwd)

# Only replace the socket when nothing is listening on it: unlinking a live
# daemon's socket orphans it (it keeps running, unreachable, until its idle
# timeout) and races a concurrent client that just spawned one. An empty answer
# is what "nothing is listening" looks like -- a daemon that answered anything
# at all is alive, and this render simply failed. The spawner puts the daemon in
# its own session; anything attached to lazygit's render pty would be SIGHUP'd
# when the pty closes after this render.
if [ -z "$reply" ]; then
  rm -f "$PIPE"
  # A failed spawn (uv.spawn returned nothing; the spawner exits 1) can never
  # produce a socket: skip the wait loop and the doomed request, so a broken
  # nvim binary or fork pressure costs nothing extra on every render.
  if nvim --clean -l "$DIR/spawn_daemon.lua" >/dev/null 2>&1; then
    # The pipe is bound once the daemon has bootstrapped its parsers, so its
    # arrival is also the signal that a render will be answered rather than
    # queued behind a second of startup.
    i=0
    while [ $i -lt 40 ] && [ ! -e "$PIPE" ]; do
      sleep 0.05
      i=$((i + 1))
    done
    serve
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
