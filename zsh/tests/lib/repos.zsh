# Sourced, after helpers.zsh, by the test files of the commands that drive git: the scratch repos
# they run on. A command under test pushes, pulls and rebases for real, so:
#
# - HOME, $REPOS_DIR and the only config git reads are inside ZT_TMP, and so is the cwd: a git call
#   missing its -C fails, instead of reaching the repo the test started in
# - git reaches no remote but a local file, which zt_repos proves before a test builds anything on
#   it, and the PATH holds the system's commands only (no gh, no toolchain)
#
#   zt_repos                                        sets that up; a test file calls it first
#   zt_commit <work tree> <subject> <file> <line>   commits <file>, holding just <line>

zt_repos() {
  [[ $ZT_TMP == /tmp/zt.?* && -d $ZT_TMP ]] || { print -ru2 -- 'ZT_TMP must be a /tmp/zt.* dir'; exit 1 }
  cd $ZT_TMP

  unset -m 'GIT_*' XDG_CONFIG_HOME
  export HOME=$ZT_TMP/home REPOS_DIR=$ZT_TMP/home/repos
  export GIT_CONFIG_GLOBAL=$ZT_TMP/gitconfig GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file
  path=(/usr/bin /bin /usr/sbin /sbin)
  mkdir -p $REPOS_DIR
  cat >$GIT_CONFIG_GLOBAL <<EOF
[user]
  name = zt
  email = zt@example.invalid
[init]
  defaultBranch = main
EOF

  local probe=$(git ls-remote git@example.invalid:fork.git 2>&1)
  t_match 'git reaches no remote but a local file' "$probe" "*transport 'ssh' not allowed*"
  # Everything a test does from here on pushes and fetches
  [[ $probe == *"transport 'ssh' not allowed"* ]] || t_done
}

zt_commit() {
  print -r -- $4 >$1/$3
  git -C $1 add $3 && git -C $1 commit -qm $2
}
