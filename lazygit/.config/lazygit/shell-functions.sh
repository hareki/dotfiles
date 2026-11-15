# lazygit's edit commands (config.yml's os.edit* and openDirInEditor), sourced into the shell it
# runs each in, quoting every path; each ends in exec, sparing a fork it would wait on (~0.7ms).

# A new nvim labelled as lazygit's, a host the nvim config's utils/ui/integration.lua knows.
lazygit_nvim() {
  NVIM_INTEGRATION=lazygit exec nvim "$@"
}

# lazygit_edit [+<line>] <path>...
#
# Inside nvim's terminal, one remote_edit call opens the paths in the host's last editing window
# (--remote would pick the current one), through Homebrew's nvim: mise's shim costs ~60ms more.
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
