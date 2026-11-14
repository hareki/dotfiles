#!/bin/sh
# Boot this working tree the way a test file's nvim boots, then run a one-off Lua payload in it:
#
#   tests/probe.sh path/to/payload.lua
#
# The payload runs once the boot is done, VeryLazy too. It can print (io.stdout:write), register
# tests through tests/lib/helpers.lua, or both; the boot ends when it returns, failing with the
# tests that failed. Boot rules: tests/lib/env.sh
set -u
. "$(cd "$(dirname "$0")" && pwd)/lib/env.sh"
trap nvim_test_cleanup EXIT

[ $# -eq 1 ] || {
  echo "usage: $0 <payload.lua>"
  exit 2
}
payload=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")

nvim_test "$(cd "$TESTS_DIR/../.." && pwd)" probe "$payload"
