# lazygit's edit commands (os.edit, editAtLine, editAtLineAndWait and openDirInEditor in
# config.yml). lazygit sources this file into the shell it runs each of them in
# (os.shellFunctionsFile), so they cost no process of their own, and it quotes every path it
# hands them.
#
# Each way through ends in exec: that shell has nothing left to do, and would otherwise fork the
# last command only to wait on it (~0.7ms).

# A new nvim, labelled as lazygit's: NVIM_INTEGRATION is one of the hosts the nvim config's
# utils/ui/integration.lua knows.
lazygit_nvim() {
  NVIM_INTEGRATION=lazygit exec nvim "$@"
}

# lazygit_edit [+<line>] <path>...
#
# Inside nvim's terminal, hand the paths to the host instance, in one call. remote_edit hides the
# Snacks terminal floats (lazygit, terminal, coding agent), refocuses the last editing window,
# opens the files there the way --remote does, and goes to the line. An expr rather than --remote
# itself, which drops the files into whatever window is current and would take a +<line> for
# another file. Each path goes in as a Vim string, a quote in it doubled. The RPC client is
# Homebrew's nvim: through mise's shim it costs ~60ms more.
#
# Anywhere else, a new nvim opens them.
lazygit_edit() {
  local line=
  case $1 in
    +*)
      line=${1#+}
      shift
      ;;
  esac

  [ -n "$NVIM" ] || lazygit_nvim ${line:++$line} -- "$@"

  # Not `path`, which zsh ties to PATH
  local quote="'" file files=
  for file in "$@"; do
    files="$files'${file//$quote/$quote$quote}',"
  done
  exec /opt/homebrew/bin/nvim --server "$NVIM" --remote-expr \
    "v:lua.require'features.git.snacks-nvim.lazygit'.remote_edit(${line:-0}, [$files])"
}
