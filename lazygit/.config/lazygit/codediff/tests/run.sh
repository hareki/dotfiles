#!/bin/sh
# Tests for the codediff renderer, its daemon and its client.
#
#   tests/run.sh                  every test file
#   tests/run.sh goldens records  the files whose name contains one of the words
#   tests/run.sh --update         rewrite the goldens (see goldens.lua)
#
# A test file is a *.lua beside this script, run by `nvim --clean -l`, or a *.zsh. bench.lua is
# a benchmark, not one of them. The files share nothing, so they run side by side and report in
# file order. Exits non-zero when a test fails or a file cannot run.
set -u

DIR=$(cd "$(dirname "$0")" && pwd)

if [ "${1:-}" = "--update" ]; then
  exec nvim --clean -l "$DIR/goldens.lua" --update
fi

OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

runs=''
for file in "$DIR"/*.lua "$DIR"/*.zsh; do
  name=$(basename "$file")
  name=${name%.*}
  [ "$name" = bench ] && continue
  if [ $# -gt 0 ]; then
    wanted=false
    for word in "$@"; do
      case $name in *"$word"*) wanted=true ;; esac
    done
    [ "$wanted" = true ] || continue
  fi

  case $file in
    *.lua) nvim --clean -l "$file" ;;
    *) "$file" ;;
  esac >"$OUT/$name" 2>&1 &
  runs="$runs $!:$name"
done

if [ -z "$runs" ]; then
  echo "no test file matches: $*"
  exit 1
fi

# Every file is waited for before any exit: the EXIT trap deletes what they are writing to
status=0
for run in $runs; do
  name=${run#*:}
  wait "${run%%:*}"
  code=$?
  echo "--- $name"
  cat "$OUT/$name"
  if [ $code -ne 0 ]; then
    status=1
    # A file that reported its failures exits 1
    [ $code -eq 1 ] || echo "BROKEN  $name (exit $code)"
  fi
done
exit $status
