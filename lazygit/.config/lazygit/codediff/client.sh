#!/bin/sh
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to plain cat as the last resort.
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
SOCK="${TMPDIR:-/tmp/}lazygit-codediff-${USER:-u}.sock"

IN=$(mktemp "${TMPDIR:-/tmp/}codediff-in.XXXXXX") || exec cat
OUT=$(mktemp "${TMPDIR:-/tmp/}codediff-out.XXXXXX") || { rm -f "$IN"; exec cat; }
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
EXPR="v:lua.CODEDIFF.render('$(esc "$IN")','$(esc "$OUT")','$(esc "$PWD")','$COLS','$OWNER','$(esc "$LAYOUT")')"

request() {
  res=$(nvim --clean --server "$SOCK" --remote-expr "$EXPR" 2>/dev/null) && [ "$res" = "ok" ]
}

if request; then
  cat "$OUT"
  exit 0
fi

# No daemon (or a stale socket): start one and retry once. The spawner puts
# the daemon in its own session; anything attached to lazygit's render pty
# would be SIGHUP'd when the pty closes after this render.
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

CODEDIFF_LAYOUT="$LAYOUT" nvim --clean -l "$DIR/render.lua" <"$IN" 2>/dev/null || cat "$IN"
exit 0
