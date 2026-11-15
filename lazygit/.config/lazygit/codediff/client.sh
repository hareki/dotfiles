#!/bin/zsh -f
# lazygit's diff renderer (GIT_PAGER), in zsh so the hot path spawns nothing (~2ms a spawn).
# Run by its shims link names, which pick the layout: an argument would cost git an `sh -c`.
LAYOUT=inline
[[ $0 == *-split ]] && LAYOUT=side-by-side

# lazygit takes a version-only OSC 1717 record ahead of all output to mean records follow, so it
# goes out first, whatever path renders: a raw diff with no records still reads as a diff.
META=0
if [[ ",${OSC1717:-}," == *[,\ ]V1[,\ ]* ]]; then
  META=1
  print -rn -- $'\e]1717;1\a'
fi

zmodload zsh/net/socket zsh/system zsh/files 2>/dev/null || exec cat

# cat without the fork: a redirection on a function call stays in this process.
pass() {
  while sysread -o 1 -s 65536; do :; done
}

# $TMPDIR ends in a slash only on macOS. The daemon is handed this name, via CODEDIFF_PIPE.
TMP=${${TMPDIR:-/tmp}%/}
PIPE=$TMP/lazygit-codediff-${USER:-u}.pipe

# A private directory, so nobody on a shared /tmp can plant a name in it for the daemon to follow.
WORK=$TMP/codediff.$$

# A `git log --graph` from lazygit's branch views, and input that can't be buffered, go straight
# through: git then stops where lazygit stops reading instead of walking the whole history.
sysread -s 65536 first
if [[ $first == '* '* ]] || ! mkdir -m 700 "$WORK" 2>/dev/null; then
  syswrite -- "$first"
  pass
  exit 0
fi

IN=$WORK/in
OUT=$WORK/out
trap 'rm -f "$IN" "$OUT"; rmdir "$WORK"' EXIT
# lazygit kills a render task once the selection moves on, and zsh runs no EXIT trap on a signal.
trap 'exit 1' HUP INT TERM PIPE

# The daemon only opens this file (lib/request.lua), so a render after cleanup has nowhere to go.
: >"$OUT"
{
  syswrite -- "$first"
  pass
} >"$IN"

# The request (lib/request.lua reads it). cwd goes last, the one field that may hold a tab.
# $COLUMNS is zsh's own: the pty's width, which lazygit sizes to the one it exports.
REQUEST="$IN	$OUT	$COLUMNS	$LAYOUT	$META	$PWD"

# Emit the render and exit if the daemon answers ok; otherwise return to fall down the ladder.
answer=""
serve() {
  zsocket "$PIPE" 2>/dev/null || return
  print -ru $REPLY -- "$REQUEST"
  read -ru $REPLY answer
  if [[ $answer == ok ]]; then
    pass <"$OUT"
    exit 0
  fi
}

serve

# Cold path from here. It starts nvim, so mise's shim, ~75ms a start, comes off the path.
DIR=${0:A:h}
path=(${path:#*/mise/shims})

# Replace the socket only when nothing answered: unlinking a live daemon's socket orphans it and
# races a client that just spawned one. Any answer means the daemon lives and this render failed.
if [[ -z $answer ]]; then
  rm -f "$PIPE"
  # The spawner waits for the socket, and only says so if one is there to ask.
  if CODEDIFF_PIPE=$PIPE nvim --clean -l "$DIR/spawn_daemon.lua" >/dev/null 2>&1; then
    serve
  fi
fi

# Last resort: a renderer for this request alone. It writes the emptied file, not a pipe, so a
# half-written render (its own or a dead daemon's) is dropped for the raw diff, not shown twice.
: >"$OUT"
if nvim --clean -l "$DIR/render.lua" "$REQUEST" >/dev/null 2>&1; then
  pass <"$OUT"
else
  pass <"$IN"
fi
