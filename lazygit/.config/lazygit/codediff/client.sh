#!/bin/sh
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
set -u

# $TMPDIR is trailing-slash-terminated on macOS but bare on most other systems.
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
SOCK="$TMP/lazygit-codediff-${USER:-u}.sock"

IN=$(mktemp "$TMP/codediff-in.XXXXXX" 2>/dev/null) || exec cat
OUT=$(mktemp "$TMP/codediff-out.XXXXXX" 2>/dev/null) || { rm -f "$IN"; exec cat; }
trap 'rm -f "$IN" "$OUT"' EXIT

cat >"$IN"
COLS="${LAZYGIT_COLUMNS:-120}"

# Optional --layout=<inline|side-by-side> from the diffRenderers command
# string; anything unrecognized renders inline.
LAYOUT="inline"
for a in "$@"; do
  case "$a" in
    --layout=*) LAYOUT="${a#--layout=}" ;;
  esac
done

# The daemon ties its lifetime to the lazygit process that owns this render.
# One ps per level: it reports the parent and the command name together, and
# shell word-splitting separates them.
OWNER=""
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

# Single quotes in a vimscript string literal are escaped by doubling. The
# arguments are two mktemp paths, $PWD, a column count and a layout name, so the
# quote is essentially never there and the common case stays fork-free.
esc() {
  case $1 in
    *\'*) printf %s "$1" | sed "s/'/''/g" ;;
    *) printf %s "$1" ;;
  esac
}
EXPR="v:lua.CODEDIFF.render('$(esc "$IN")','$(esc "$OUT")','$(esc "$PWD")','$(esc "$COLS")','$OWNER','$(esc "$LAYOUT")')"

request() {
  res=$(nvim --clean --server "$SOCK" --remote-expr "$EXPR" 2>/dev/null) && [ "$res" = "ok" ]
}

if request; then
  cat "$OUT"
  exit 0
fi

# The render failed. Everything from here down is a cold path, and only these
# paths need the script's own directory.
DIR=$(cd "$(dirname "$0")" && pwd)

# Only replace the socket when nothing is listening on it: unlinking a live
# daemon's socket orphans it (it keeps running, unreachable, until its idle
# timeout) and races a concurrent client that just spawned one. The spawner puts
# the daemon in its own session; anything attached to lazygit's render pty would
# be SIGHUP'd when the pty closes after this render. The -S test short-circuits
# the cold path, where the probe would be a second full nvim startup only to
# rediscover that there is nothing to connect to.
if [ ! -S "$SOCK" ] || ! nvim --clean --server "$SOCK" --remote-expr 1 >/dev/null 2>&1; then
  rm -f "$SOCK"
  # A failed spawn (uv.spawn returned nothing; the spawner exits 1) can never
  # produce a socket: skip the wait loop and the doomed request, so a broken
  # nvim binary or fork pressure costs nothing extra on every render.
  if nvim --clean -l "$DIR/spawn_daemon.lua" "$SOCK" >/dev/null 2>&1; then
    i=0
    while [ $i -lt 40 ] && [ ! -e "$SOCK" ]; do
      sleep 0.05
      i=$((i + 1))
    done
    if request; then
      cat "$OUT"
      exit 0
    fi
  fi
fi

# Last resort. Written to a file rather than piped, because nvim can die (parser
# crash, OOM, a signal) with part of the render already on stdout: appending the
# raw diff to a half-written one would show the hunks twice.
if CODEDIFF_LAYOUT="$LAYOUT" nvim --clean -l "$DIR/render.lua" <"$IN" >"$OUT" 2>/dev/null; then
  cat "$OUT"
else
  cat "$IN"
fi
exit 0
