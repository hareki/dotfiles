#!/bin/dash
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
#
# lazygit starts this script again for every diff it draws, so the transport is
# paid on every keypress that moves the selection -- and a small diff renders in
# well under a millisecond, which makes the client the whole cost. The request
# therefore goes over the daemon's plain line socket with `nc` (~4ms round
# trip), rather than through an `nvim --remote-expr` client that would spend
# ~36ms on startup before it said a word. That is also why this is dash: macOS's
# /bin/sh is a shim that execs bash.
set -u

# lazygit offers its OSC 1717 diff-line protocol through $OSC1717, naming the
# versions it understands, and decides whether it can act on what we render by
# looking for a version-only record ahead of everything else (it runs us once
# on empty input to ask). So the handshake goes out first, whichever path below
# ends up rendering: every one of them either puts a record ahead of the rows
# lazygit can place (lib/osc1717.lua) or passes the diff through as git wrote
# it, which lazygit reads as a diff when it finds no records. The rows left
# without one (a combined diff, a path holding a control byte) are just rows it
# can't act on.
META=0
case ",${OSC1717:-}," in
  *[,\ ]V1[,\ ]*)
    META=1
    printf '\033]1717;1\007'
    ;;
esac

# $TMPDIR is trailing-slash-terminated on macOS but bare on most other systems.
# This is the one place the socket name is derived: the daemon is handed the
# result through CODEDIFF_PIPE at spawn time rather than rebuilding it in Lua.
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
PIPE="$TMP/lazygit-codediff-${USER:-u}.pipe"

# The two files handed to the daemon sit in a private directory, so nobody else
# on a shared /tmp can plant a name in there for it to follow. The output exists
# up front because the daemon only ever opens it (see write_output in
# daemon.lua): once the cleanup below has run, a late render has nothing to
# write to.
WORK=$(mktemp -d "$TMP/codediff.XXXXXX" 2>/dev/null) || exec cat
IN="$WORK/in"
OUT="$WORK/out"
trap 'rm -rf "$WORK"' EXIT
# lazygit terminates a render task as soon as the selection moves on, and dash
# runs no EXIT trap for a signal that kills it.
trap 'exit 1' HUP INT TERM

cat >"$IN"
: >"$OUT"

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
#
# Deliberately after the rendered bytes are on their way out: registering an
# owner costs a process tree walk, and nothing about this render depends on it.
# lazygit terminates the render task (SIGTERM, then the pty's SIGHUP) as soon as
# the selection moves on, and the answer to a question asked this rarely must not
# be lost to that: the walk takes ~15ms, ignoring both for that long is harmless,
# and answering `0` (nothing found) is what stops the daemon asking again.
reply=""
register_owner() {
  [ "$reply" = "ok:owner" ] || return 0
  trap '' TERM HUP
  owner=0
  pid=$$
  for _ in 1 2 3 4 5 6 7; do
    # shellcheck disable=SC2046 # deliberate word-splitting into ppid + comm
    set -- $(ps -o ppid=,comm= -p "$pid" 2>/dev/null)
    [ $# -ge 2 ] || break
    parent=$1
    shift
    case "$*" in
      *lazygit*) owner=$pid; break ;;
    esac
    [ "$parent" -gt 1 ] 2>/dev/null || break
    pid=$parent
  done
  printf 'owner\t%s\n' "$owner" | nc -U "$PIPE" >/dev/null 2>&1
}

# Emit the render and exit if the daemon answers; returns so the caller can fall
# further down the ladder if it did not.
#
# One line in, one line back. cwd goes last because it is the only field that
# can legitimately contain a tab. An unset COLUMNS goes as an empty field, and
# the renderer picks its default width. A heredoc because `printf | nc` costs
# another fork, and the tabs in it are the field separators.
#
# The -S test keeps a cold start from paying for a connection attempt to a
# socket that is not there.
serve() {
  [ -S "$PIPE" ] || return
  reply=$(nc -U "$PIPE" 2>/dev/null <<EOF
render	$IN	$OUT	${COLUMNS:-}	$LAYOUT	$META	$PWD
EOF
  )
  case "$reply" in
    ok | ok:owner)
      cat "$OUT"
      register_owner
      exit 0
      ;;
  esac
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
  if CODEDIFF_PIPE="$PIPE" nvim --clean -l "$DIR/spawn_daemon.lua" >/dev/null 2>&1; then
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
if CODEDIFF_LAYOUT="$LAYOUT" CODEDIFF_METADATA="$META" nvim --clean -l "$DIR/render.lua" <"$IN" >"$OUT" 2>/dev/null; then
  cat "$OUT"
else
  cat "$IN"
fi
exit 0
