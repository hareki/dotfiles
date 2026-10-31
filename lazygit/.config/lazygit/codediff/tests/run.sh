#!/bin/sh
# Golden-output regression tests for the codediff renderer.
#
#   tests/run.sh           compare every fixtures/*.diff against its .out
#   tests/run.sh --update  regenerate the golden .out files
#
# Renders use CODEDIFF_FORCE_FRAGMENT=1 (no git blob lookups) and a fixed width
# so fixtures are reproducible outside the repos they were captured from. The
# OSC 1717 records lazygit asks for are checked separately, against the
# fixtures' own patches (see records.lua).
set -u

DIR=$(cd "$(dirname "$0")" && pwd)
RENDER="$DIR/../render.lua"
UPDATE="${1:-}"
fail=0

for diff_file in "$DIR"/fixtures/*.diff; do
  [ -e "$diff_file" ] || { echo "no fixtures found"; exit 0; }
  for layout in inline side-by-side; do
    if [ "$layout" = "inline" ]; then
      golden="${diff_file%.diff}.out"
    else
      golden="${diff_file%.diff}.split.out"
    fi
    # A failed render must not reach --update, which would record what little
    # it wrote as the new golden.
    if ! actual=$(CODEDIFF_FORCE_FRAGMENT=1 CODEDIFF_LAYOUT="$layout" COLUMNS=100 nvim --clean -l "$RENDER" <"$diff_file" 2>/dev/null); then
      echo "BROKEN  $(basename "$diff_file") ($layout): the render failed"
      fail=1
      continue
    fi
    if [ "$UPDATE" = "--update" ]; then
      printf '%s\n' "$actual" >"$golden"
      echo "updated $(basename "$golden")"
    elif [ ! -e "$golden" ]; then
      echo "MISSING golden: $(basename "$golden") (run with --update)"
      fail=1
    elif [ "$actual" = "$(cat "$golden")" ]; then
      echo "ok      $(basename "$diff_file") ($layout)"
    else
      echo "FAILED  $(basename "$diff_file") ($layout)"
      fail=1
    fi
  done
done

nvim --clean -l "$DIR/records.lua" 2>/dev/null || fail=1

exit $fail
