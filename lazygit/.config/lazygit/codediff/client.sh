#!/bin/sh
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
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
OWNER=""
pid=$$
for _ in 1 2 3 4 5 6; do
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -n "$pid" ] && [ "$pid" -gt 1 ] || break
  case "$(ps -o comm= -p "$pid" 2>/dev/null)" in
    *lazygit*) OWNER=$pid; break ;;
  esac
done

# Single quotes in a vimscript string literal are escaped by doubling.
esc() { printf %s "$1" | sed "s/'/''/g"; }
EXPR="v:lua.CODEDIFF.render('$(esc "$IN")','$(esc "$OUT")','$(esc "$PWD")','$(esc "$COLS")','$OWNER','$(esc "$LAYOUT")')"

request() {
  res=$(nvim --clean --server "$SOCK" --remote-expr "$EXPR" 2>/dev/null) && [ "$res" = "ok" ]
}

if request; then
  cat "$OUT"
  exit 0
fi

# The render failed. Only replace the socket when nothing is listening on it:
# unlinking a live daemon's socket orphans it (it keeps running, unreachable,
# until its idle timeout) and races a concurrent client that just spawned one.
# The spawner puts the daemon in its own session; anything attached to
# lazygit's render pty would be SIGHUP'd when the pty closes after this render.
if ! nvim --clean --server "$SOCK" --remote-expr 1 >/dev/null 2>&1; then
  rm -f "$SOCK"
  nvim --clean -l "$DIR/spawn_daemon.lua" "$SOCK" >/dev/null 2>&1
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

# Last resort. Buffered, because nvim can die (parser crash, OOM, a signal)
# after the emitter has already streamed part of the render: appending the raw
# diff to a half-rendered one would show the hunks twice.
if CODEDIFF_LAYOUT="$LAYOUT" nvim --clean -l "$DIR/render.lua" <"$IN" >"$OUT" 2>/dev/null; then
  cat "$OUT"
else
  cat "$IN"
fi
exit 0
