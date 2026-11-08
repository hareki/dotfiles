#!/bin/sh
# Run the test files in tests/ (each *.lua beside this script), each in its own headless nvim
# booted on this working tree:
#
#   tests/run.sh             every test file
#   tests/run.sh popup keys  the files whose name contains one of the words
#
# Exits non-zero when a test fails or a file cannot run. Boot rules: tests/lib/env.sh
set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/env.sh"
trap nvim_test_cleanup EXIT

CONFIG_PARENT=$(cd "$TESTS_DIR/../.." && pwd)
status=0
ran=0

for file in "$TESTS_DIR"/*.lua; do
  name=$(basename "$file" .lua)
  if [ $# -gt 0 ]; then
    wanted=false
    for word in "$@"; do
      case $name in *"$word"*) wanted=true ;; esac
    done
    [ "$wanted" = true ] || continue
  fi

  ran=$((ran + 1))
  nvim_test "$CONFIG_PARENT" "$name" "$file"
  code=$?
  if [ $code -ne 0 ]; then
    status=1
    # A file that reported its failures exits 1; 137 is gtimeout's SIGKILL
    [ $code -eq 1 ] || echo "BROKEN $name (exit $code)"
  fi
done

[ $ran -gt 0 ] || {
  echo "no test file matches: $*"
  exit 1
}
exit $status
