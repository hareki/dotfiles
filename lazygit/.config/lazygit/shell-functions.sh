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
# Inside nvim's terminal, hand the paths to the host instance. The expr call hides the Snacks
# terminal floats (lazygit, terminal, coding agent) and refocuses the last editing window first,
# since --remote drops the file into whatever window is current. The RPC clients are Homebrew's
# nvim: through mise's shim each one costs ~60ms more. The line goes last, as keys, because
# --remote would take a +<line> for another file.
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

  local host=/opt/homebrew/bin/nvim
  "$host" --server "$NVIM" --remote-expr "v:lua.require'features.git.snacks-nvim.lazygit'.prepare_remote_edit()" || return
  [ -n "$line" ] || exec "$host" --server "$NVIM" --remote "$@"
  "$host" --server "$NVIM" --remote "$@" && exec "$host" --server "$NVIM" --remote-send ":$line<CR>"
}
