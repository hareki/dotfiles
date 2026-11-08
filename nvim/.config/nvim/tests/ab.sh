#!/bin/sh
# Boot a committed revision (HEAD by default) and this working tree side by side, dump what each
# config defines once every plugin has loaded (maps, highlights, autocmds, options, plugin opts,
# LSP configs, which-key specs and icons; tests/lib/dump.lua), and print the diff:
#
#   tests/ab.sh            HEAD against the working tree
#   tests/ab.sh <rev>      <rev> against the working tree
#
# NVIM_AB_KEEP=<dir> keeps both dumps there. Exits 0 when they match, 1 when they differ, 2 when a
# boot failed. Boot rules: tests/lib/env.sh
set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/env.sh"
trap nvim_test_cleanup EXIT

rev=${1:-HEAD}
CONFIG=$(cd "$TESTS_DIR/.." && pwd)
REPO=$(git -C "$CONFIG" rev-parse --show-toplevel)
PREFIX=$(git -C "$CONFIG" rev-parse --show-prefix)
mkdir -p "$NVIM_TEST_TMP/old/nvim" "$NVIM_TEST_TMP/new/nvim"

# From the top: run in a subdirectory, git archive keeps only that path inside the tree it is given
git -C "$REPO" archive "$rev:$PREFIX" | tar -x -C "$NVIM_TEST_TMP/old/nvim" || exit 2
# Regular files only: .codegraph holds a socket, which copy tools choke on
(cd "$CONFIG" && find . \( -name .git -o -name .codegraph \) -prune -o -type f -print |
  tar -cf - -T -) | tar -x -C "$NVIM_TEST_TMP/new/nvim" || exit 2

# Side by side: each boot has its own config, cache and state dirs (tests/lib/env.sh)
nvim_test "$NVIM_TEST_TMP/old" old "$TESTS_DIR/lib/dump.lua" "$NVIM_TEST_TMP/old.txt" &
old_pid=$!
nvim_test "$NVIM_TEST_TMP/new" new "$TESTS_DIR/lib/dump.lua" "$NVIM_TEST_TMP/new.txt" &
new_pid=$!
# Both waited for before any exit: the EXIT trap deletes the dirs they write to
broken=false
wait "$old_pid" || { echo 'BROKEN the old boot failed'; broken=true; }
wait "$new_pid" || { echo 'BROKEN the new boot failed'; broken=true; }
[ "$broken" = false ] || exit 2

if [ -n "${NVIM_AB_KEEP:-}" ]; then
  mkdir -p "$NVIM_AB_KEEP"
  cp "$NVIM_TEST_TMP/old.txt" "$NVIM_TEST_TMP/new.txt" "$NVIM_AB_KEEP/"
fi

cd "$NVIM_TEST_TMP" && diff -u --label "$rev" --label 'working tree' old.txt new.txt
