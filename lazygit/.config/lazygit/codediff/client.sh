#!/bin/zsh -f
# codediff client: lazygit's diff renderer entry point (GIT_PAGER).
# Ships the diff to a persistent headless-nvim daemon; falls back to a
# one-shot render, and to the diff as git wrote it as the last resort.
#
# lazygit starts this script again for every diff it draws, so the transport is
# paid on every keypress that moves the selection -- and a small diff renders in
# well under a millisecond, which makes the client the whole cost. That is why
# this is zsh: all the hot path needs (a directory, a socket, copying bytes) is a
# builtin here, where mktemp, nc, cat and rm would each be a ~2ms spawn. -f keeps
# the user's startup files out of it.
#
# config.yml runs this by the names of its two links in bin/.local/bin/shims,
# because git hands a pager command holding a shell metacharacter (a ~, a space,
# a =) to `sh -c`, ~2.6ms per diff. So a path can't name it, an argument can't
# select the layout, and the name it was run by does.
LAYOUT=inline
[[ $0 == *-split ]] && LAYOUT=side-by-side

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
if [[ ",${OSC1717:-}," == *[,\ ]V1[,\ ]* ]]; then
  META=1
  print -rn -- $'\e]1717;1\a'
fi

zmodload zsh/net/socket zsh/system zsh/files 2>/dev/null || exec cat

# cat without the fork: a redirection on a function call stays in this process.
pass() {
  while sysread -o 1 -s 65536; do :; done
}

# $TMPDIR is trailing-slash-terminated on macOS but bare on most other systems.
# This is the one place the socket name is derived: the daemon is handed the
# result through CODEDIFF_PIPE at spawn time rather than rebuilding it in Lua.
TMP=${${TMPDIR:-/tmp}%/}
PIPE=$TMP/lazygit-codediff-${USER:-u}.pipe

# The two files handed to the daemon sit in a private directory, so nobody else
# on a shared /tmp can plant a name in there for it to follow.
WORK=$TMP/codediff.$$

# lazygit's branch views run their `git log --graph` through here too, and the
# renderer hands one back as it came (see core.render). Going through it means
# git walks the whole history for the screenful lazygit reads, so a graph goes
# straight through from its first bytes, and git stops where lazygit stops
# reading. So does anything that has nowhere to be buffered.
sysread -s 65536 first
if [[ $first == '* '* ]] || ! mkdir -m 700 "$WORK" 2>/dev/null; then
  syswrite -- "$first"
  pass
  exit 0
fi

IN=$WORK/in
OUT=$WORK/out
trap 'rm -f "$IN" "$OUT"; rmdir "$WORK"' EXIT
# lazygit terminates a render task as soon as the selection moves on, and zsh
# runs no EXIT trap for a signal that kills it.
trap 'exit 1' HUP INT TERM PIPE

# The output exists up front because the daemon only ever opens it (see
# write_output in daemon.lua): once the cleanup above has run, a late render has
# nothing to write to.
: >"$OUT"
{
  syswrite -- "$first"
  pass
} >"$IN"

# Emit the render and exit if the daemon answers; returns so the caller can fall
# further down the ladder if it did not.
#
# One line in, one line back. cwd goes last because it is the only field that
# can legitimately contain a tab, and the tabs in the request are the field
# separators. $COLUMNS is zsh's own, the width of the pty rather than the
# variable in the environment, and lazygit sizes the one to the other.
answer=""
serve() {
  zsocket "$PIPE" 2>/dev/null || return
  print -ru $REPLY -- "$IN	$OUT	$COLUMNS	$LAYOUT	$META	$PWD"
  read -ru $REPLY answer
  if [[ $answer == ok ]]; then
    pass <"$OUT"
    exit 0
  fi
}

serve

# The render failed. Everything from here down is a cold path, and only these
# paths need the script's own directory. They start nvim, which mise's shim only
# falls through to, at ~75ms a start.
DIR=${0:A:h}
path=(${path:#*/mise/shims})

# Only replace the socket when nothing is listening on it: unlinking a live
# daemon's socket orphans it (it keeps running, unreachable, until its idle
# timeout) and races a concurrent client that just spawned one. An empty answer
# is what "nothing is listening" looks like -- a daemon that answered anything
# at all is alive, and this render simply failed. The spawner puts the daemon in
# its own session; anything attached to lazygit's render pty would be SIGHUP'd
# when the pty closes after this render.
if [[ -z $answer ]]; then
  rm -f "$PIPE"
  # The spawner waits for the socket, and only says so if one is there to ask.
  if CODEDIFF_PIPE=$PIPE nvim --clean -l "$DIR/spawn_daemon.lua" >/dev/null 2>&1; then
    serve
  fi
fi

# Last resort. Written to a file rather than piped, because nvim can die (parser
# crash, OOM, a signal) with part of the render already on stdout: appending the
# raw diff to a half-written one would show the hunks twice.
if CODEDIFF_LAYOUT=$LAYOUT CODEDIFF_METADATA=$META nvim --clean -l "$DIR/render.lua" <"$IN" >"$OUT" 2>/dev/null; then
  pass <"$OUT"
else
  pass <"$IN"
fi
