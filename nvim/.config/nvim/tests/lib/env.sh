# Sourced by the scripts beside tests/lib (run.sh, ab.sh, probe.sh), which is where it looks for
# boot.lua: the environment every headless boot of this config gets. Each rule below once cost a
# runaway process tree or a false result:
#
# - XDG_DATA_HOME stays the real one, since plugins and parsers load from it. Overridden once, it
#   led mise to an empty data dir, where a shim recursion spawned about 3,500 processes
# - XDG_CONFIG_HOME, XDG_CACHE_HOME and XDG_STATE_HOME move into a private dir per run (no real
#   undo, swap, log or compile caches); mise reads them too, so its dirs stay real, installs off
# - Homebrew's nvim runs, not the mise shim, which blocks on an install under moved dirs
# - NVIM_INTEGRATION (it swaps lualine for a label), NVIM (set in nvim's terminals) and TMUX unset
# - Every boot ends in os.exit, which skips VimLeavePre: no session save, no harpoon sync and no
#   LSP shutdown, which is why tests/lib/boot.lua stubs vim.lsp.start
# - Each boot runs in a cwd of its own, so the files one writes stay out of the next one's pickers;
#   harpoon still writes a list for every cwd it boots in, which nvim_test_cleanup deletes
# - Never dump the environment (`ps -E`): it holds API keys

: "${MISE_DATA_DIR:=${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
: "${MISE_CONFIG_DIR:=${XDG_CONFIG_HOME:-$HOME/.config}/mise}"
: "${MISE_STATE_DIR:=${XDG_STATE_HOME:-$HOME/.local/state}/mise}"
if [ -z "${MISE_CACHE_DIR:-}" ]; then
  if [ -n "${XDG_CACHE_HOME:-}" ]; then
    MISE_CACHE_DIR=$XDG_CACHE_HOME/mise
  elif [ "$(uname)" = Darwin ]; then
    MISE_CACHE_DIR=$HOME/Library/Caches/mise
  else
    MISE_CACHE_DIR=$HOME/.cache/mise
  fi
fi
export MISE_DATA_DIR MISE_CONFIG_DIR MISE_STATE_DIR MISE_CACHE_DIR
export MISE_NOT_FOUND_AUTO_INSTALL=false MISE_EXEC_AUTO_INSTALL=false MISE_TASK_RUN_AUTO_INSTALL=false
# codediff.nvim may download its native library when it thinks it is outdated
export VSCODE_DIFF_NO_AUTO_INSTALL=1

if [ -z "${NVIM_BIN:-}" ]; then
  if [ -x /opt/homebrew/bin/nvim ]; then
    NVIM_BIN=/opt/homebrew/bin/nvim
  else
    NVIM_BIN=$(command -v nvim)
  fi
fi
TIMEOUT_BIN=$(command -v gtimeout || command -v timeout)
: "${NVIM_TEST_TIMEOUT:=120}"

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
tmp_base=${TMPDIR:-/tmp}
NVIM_TEST_TMP=$(mktemp -d "${tmp_base%/}/nvim-tests.XXXXXX")

# nvim_test <config parent> <variant> <payload.lua> [out]: boot the config at <config parent>/nvim,
# then run the payload (tests/lib/boot.lua); <variant> names its private cwd, cache and state dirs
nvim_test() {
  (
    mkdir -p "$NVIM_TEST_TMP/$2/cwd" && cd "$NVIM_TEST_TMP/$2/cwd" &&
      XDG_CONFIG_HOME=$1 \
        XDG_CACHE_HOME=$NVIM_TEST_TMP/$2/cache \
        XDG_STATE_HOME=$NVIM_TEST_TMP/$2/state \
        NVIM_TEST_PAYLOAD=$3 \
        NVIM_TEST_OUT=${4:-} \
        NVIM_TEST_CONFIG=$1/nvim \
        env -u NVIM_INTEGRATION -u NVIM -u TMUX \
        "$TIMEOUT_BIN" -s KILL "$NVIM_TEST_TIMEOUT" \
        "$NVIM_BIN" --headless -i NONE -c "luafile $TESTS_DIR/lib/boot.lua"
  )
}

nvim_test_cleanup() {
  for cwd in "$NVIM_TEST_TMP"/*/cwd; do
    [ -d "$cwd" ] || continue
    # What vim.uv.cwd() reports (/private/var/... on macOS), which harpoon hashes for its list
    hash=$(cd "$cwd" && pwd -P | tr -d '\n' | sha256sum | cut -d ' ' -f 1)
    rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/harpoon/$hash.json"
  done
  rm -rf "$NVIM_TEST_TMP"
}
