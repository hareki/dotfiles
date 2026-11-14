#!/bin/sh
# Run the test files in tests/ (each *.lua beside this script), each in its own headless nvim
# booted on this working tree, all side by side:
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
boots=''

for file in "$TESTS_DIR"/*.lua; do
  name=$(basename "$file" .lua)
  if [ $# -gt 0 ]; then
    wanted=false
    for word in "$@"; do
      case $name in *"$word"*) wanted=true ;; esac
    done
    [ "$wanted" = true ] || continue
  fi

  # Each boot has its own cwd, cache and state dirs (tests/lib/env.sh), so none waits for another
  nvim_test "$CONFIG_PARENT" "$name" "$file" >"$NVIM_TEST_TMP/$name.out" 2>&1 &
  boots="$boots $!:$name"
done

[ -n "$boots" ] || {
  echo "no test file matches: $*"
  exit 1
}

# Reported in file order, and every boot waited for before any exit: the EXIT trap deletes their dirs
for boot in $boots; do
  name=${boot#*:}
  wait "${boot%%:*}"
  code=$?
  cat "$NVIM_TEST_TMP/$name.out"
  if [ $code -ne 0 ]; then
    status=1
    # A file that reported its failures exits 1; 137 is gtimeout's SIGKILL
    [ $code -eq 1 ] || echo "BROKEN $name (exit $code)"
  fi
done
exit $status
