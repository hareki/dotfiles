# sync-forks against stand-ins for GitHub. Each fork gets a bare upstream (remote/up/<n>.git) and a
# bare fork of it (remote/hareki/<n>.git), which the URLs sync-forks builds reach through
# url.insteadOf rewrites, plus the fork's clone in $REPOS_DIR, and a gh stub lists their heads.
# Every scenario is one fork in a single listing, synced twice: the second run, on what the first
# left, checks that a sync settles

source "$ZT_LIB/helpers.zsh"

# sync-forks runs inside an interactive shell, so it runs here under that shell's options: those
# `setopt` lists in one, bar the interactive-only ones (the "options set" in a tests/ab.zsh dump)
interactive_options=(
  multios long_list_jobs interactive_comments prompt_subst auto_cd combining_chars
  extended_history hist_expire_dups_first hist_ignore_dups hist_ignore_space hist_verify
  share_history complete_in_word always_to_end auto_menu hash_dirs no_flow_control no_global_rcs
)

# HOME and git's global config move in here
[[ $ZT_TMP == /tmp/zt.?* && -d $ZT_TMP ]] || { print -ru2 -- 'ZT_TMP must be a /tmp/zt.* dir'; exit 1 }
root=$ZT_TMP
# A git call missing its -C then fails, instead of reaching the repo the test started in
cd $root

# Before any git call: git reads no config but this one, whose rewrites send every GitHub URL
# sync-forks builds to a bare repo here, and a URL they miss fails rather than reach the network.
# The real gh isn't on this PATH either
unset -m 'GIT_*' XDG_CONFIG_HOME
export HOME=$root/home REPOS_DIR=$root/home/repos
export GIT_CONFIG_GLOBAL=$root/gitconfig GIT_CONFIG_NOSYSTEM=1 GIT_ALLOW_PROTOCOL=file
path=(/usr/bin /bin /usr/sbin /sbin)
mkdir -p $REPOS_DIR
cat >$GIT_CONFIG_GLOBAL <<EOF
[url "file://$root/remote/"]
  insteadOf = https://github.com/
[url "file://$root/remote/hareki/"]
  insteadOf = git@gh-personal:hareki/
[user]
  name = zt
  email = zt@example.invalid
[init]
  defaultBranch = main
EOF

probe=$(git ls-remote git@example.invalid:fork.git 2>&1)
t_match 'a remote URL the rewrites miss fails' "$probe" "*transport 'ssh' not allowed*"
# Everything below pushes and fetches
[[ $probe == *"transport 'ssh' not allowed"* ]] || t_done

autoload -Uz $ZT_PKG/.config/zsh/functions/{sync-forks,print-header}

# --- Stand-ins

# A dummy token, and GitHub's listing of gh_forks as the GraphQL query's --jq prints it: 6 lines per
# fork, read from the bare repos unless pinned. Named apart from sync-forks' locals, which shadow
# globals for whatever it calls
typeset -a gh_forks
typeset -A gh_pinned
gh() {
  local n
  case $1/$2 in
    auth/token) print -r -- zt-dummy-token ;;
    api/graphql)
      for n in $gh_forks; do
        print -r -- "${gh_pinned[$n]-$(listing $n)}"
      done ;;
    *) print -ru2 -- "gh stub: unexpected gh $*"; return 1 ;;
  esac
}

# listing <n>: name, branch and head of the fork, then the same of its upstream
listing() {
  print -rl -- $1 main $(git -C $root/remote/hareki/$1.git rev-parse main) \
    up/$1 main $(git -C $root/remote/up/$1.git rev-parse main)
}

# pin <n>: the listing keeps showing the fork as it is now
pin() {
  gh_pinned[$1]=$(listing $1)
}

# Logs what sync-forks sends over the network while net_log is set: clones, pushes and fetches, but
# `fetch .`, which moves a branch locally
git() {
  if [[ -n $net_log ]]; then
    local -a args=(${@[2,-1]:#-*})
    case $1 in
      clone) print -r -- "${args[-1]:t} clone" ;;
      push) print -r -- "${PWD:t} push" ;;
      fetch) [[ $args[1] == . ]] || print -r -- "${PWD:t} fetch ${args[1]/#https:*/upstream}" ;;
    esac >>$net_log
  fi
  command git "$@"
}

# --- Fixtures

# commit_in <work tree> <subject> <file> <line>: commits <file>, holding just <line>
commit_in() {
  print -r -- $4 >$1/$3
  git -C $1 add $3 && git -C $1 commit -qm $2
}

# upstream_commit/fork_commit <n> <subject> <file> <line>: the same, pushed to the upstream or the
# fork from its work clone
upstream_commit() {
  commit_in $root/work/up/$1 "${@[2,-1]}" && git -C $root/work/up/$1 push -q origin HEAD:main
}
fork_commit() {
  commit_in $root/work/hareki/$1 "${@[2,-1]}" && git -C $root/work/hareki/$1 push -q origin HEAD:main
}

# new_fork <n>: upstream up/<n> at u1, its fork hareki/<n>, a work clone of each, and the fork in
# the listing
new_fork() {
  local up=$root/remote/up/$1.git fork=$root/remote/hareki/$1.git work=$root/work/up/$1
  gh_forks+=($1)
  git init -q $work &&
    commit_in $work u1 shared.txt base &&
    git clone -q --bare $work $up &&
    git -C $work remote add origin $up &&
    git clone -q --bare $up $fork &&
    git clone -q $fork $root/work/hareki/$1
}

# current <n>: the fork's own commit f1 on upstream's head
current() {
  new_fork $1 && fork_commit $1 f1 fork.txt f1
}

# behind <n>: then upstream moves on with u2, which touches another file
behind() {
  current $1 && upstream_commit $1 u2 upstream.txt u2
}

# conflicting <n>: the fork's f1, then upstream's u2, change the same line
conflicting() {
  new_fork $1 && fork_commit $1 f1 shared.txt fork && upstream_commit $1 u2 shared.txt upstream
}

# merge_upstream <n>: the fork merges upstream's head, the way the wei/pull app synced forks
merge_upstream() {
  local work=$root/work/hareki/$1
  git -C $work fetch -q $root/remote/up/$1.git main &&
    git -C $work merge -q --no-edit -m merge FETCH_HEAD &&
    git -C $work push -q origin HEAD:main
}

# clone_fork <n>: the fork's clone in $REPOS_DIR, laid out like those sync-forks makes
clone_fork() {
  git clone -q git@gh-personal:hareki/$1.git $REPOS_DIR/$1 &&
    git -C $REPOS_DIR/$1 remote add upstream https://github.com/up/$1.git
}

# in_clone <n> <git args>: git in the fork's clone
in_clone() {
  git -C $REPOS_DIR/$1 "${@[2,-1]}"
}

# rebased_locally <n>: the clone's main rebased onto upstream's head by hand, keeping the fork's
# line, and not pushed
rebased_locally() {
  in_clone $1 fetch -q upstream &&
    in_clone $1 reset -q --hard upstream/main &&
    commit_in $REPOS_DIR/$1 f1 shared.txt fork
}

# --- Checks

typeset -A want_line want_state
# expect <n> <line in run 1> <state after it> <line in run 2> [<state after it>]: the fork's report
# line past "<n>: ", and its state (see state). Without a state after run 2, run 2 must leave the
# fork's repos exactly as run 1 did
expect() {
  want_line[1/$1]=$2 want_state[1/$1]=$3 want_line[2/$1]=$4
  (( $# < 5 )) || want_state[2/$1]=$5
}

# run_sync <run>: sync-forks into <run>.out and <run>.err, its network use into <run>.net, its exit
# status into rc
run_sync() {
  setopt local_options $interactive_options
  net_log=$root/$1.net
  : >$net_log
  sync-forks -j 1 >$root/$1.out 2>$root/$1.err
  rc=$?
  net_log=
}

# plain <file>: a run's output without SGR escapes, and the oid in a refused push's line masked
plain() {
  setopt local_options extended_glob
  local text=$(<$1)
  text=${text//$'\e'\[[0-9;]#m}
  print -r -- "${text//[0-9a-f](#c40)/<oid>}"
}

# report <run>: the header, then each fork's line expected in <run>
report() {
  local n
  print -rl -- '' '======== Syncing forks of hareki ========'
  for n in $gh_forks; do
    print -r -- "$n: $want_line[$1/$n]"
  done
}

# network <run>: the run's network calls, a line per fork
network() {
  local fork call last
  local -a lines
  while read -r fork call; do
    if [[ $fork == $last ]]; then
      lines[-1]+=", $call"
    else
      lines+=("$fork: $call") last=$fork
    fi
  done <$root/$1.net
  print -rl -- $lines
}

# subjects <repo> <rev>: the subjects of the commits leading to <rev>, oldest first
subjects() {
  print -r -- ${(f)"$(git -C $1 log --first-parent --reverse --format=%s $2)"}
}

# state <n>: the fork's branch on GitHub and the clone's branch as their subjects (main=github: the
# very commit on GitHub), the clone's HEAD, a rebase in progress there and its uncommitted changes
state() {
  local fork=$root/remote/hareki/$1.git clone=$REPOS_DIR/$1 head changes
  local -a out=(github=none)
  [[ -d $fork ]] && out=("github=$(subjects $fork main)")
  if [[ ! -d $clone ]]; then
    out+=(clone=none)
  else
    if [[ $(git -C $clone rev-parse main) == $(git -C $fork rev-parse main 2>/dev/null) ]]; then
      out+=(main=github)
    else
      out+=("main=$(subjects $clone main)")
    fi
    head=$(git -C $clone symbolic-ref -q --short HEAD) || head=detached
    out+=(HEAD=$head $clone/.git/rebase-*(N:t))
    changes=$(git -C $clone status --porcelain -uno)
    [[ -n $changes ]] && out+=("changes=${(j:,:)${${(f)changes}# }}")
  fi
  print -r -- ${(j:; :)out}
}

# snapshot <n>: all of the fork's that a run could move, oids and all: the refs on GitHub and in the
# clone, the clone's HEAD, its worktree and a rebase in progress there
snapshot() {
  local clone=$REPOS_DIR/$1
  git -C $root/remote/hareki/$1.git for-each-ref 2>/dev/null
  [[ -d $clone ]] || return 0
  git -C $clone for-each-ref
  git -C $clone rev-parse HEAD
  git -C $clone symbolic-ref -q HEAD
  git -C $clone status --porcelain
  print -rl -- $clone/.git/rebase-*(N:t)
}

# same_lines <what> <actual> <expected>: t_ok over a diff, which shows the lines that differ
same_lines() {
  t_ok $1 diff -u --label expected --label actual <(print -r -- "$3") <(print -r -- "$2")
}

# --- Scenarios, in listing order

# Up to date: upstream has nothing the fork lacks, and neither side is fetched
current uptodate
clone_fork uptodate
expect uptodate 'up to date' 'github=u1 f1; main=github; HEAD=main' 'up to date'

# Behind upstream: rebased, pushed, and the clone's checked-out branch reset onto it
behind rebase
clone_fork rebase
expect rebase \
  'synced with up/rebase:main (rebase), pulled main in ~/repos/rebase' \
  'github=u1 u2 f1; main=github; HEAD=main' \
  'up to date'

# ...with another branch checked out in the clone, so only the ref moves
behind rebase-other
clone_fork rebase-other
in_clone rebase-other switch -qc other
expect rebase-other \
  'synced with up/rebase-other:main (rebase), pulled main in ~/repos/rebase-other' \
  'github=u1 u2 f1; main=github; HEAD=other' \
  'up to date'

# ...with local changes in the clone, which stays put. In run 2 only the reflog still shows that the
# clone's branch was on origin (--fork-point), which keeps it "local changes", not "diverged"
behind rebase-dirty
clone_fork rebase-dirty
print local >>$REPOS_DIR/rebase-dirty/shared.txt
expect rebase-dirty \
  'synced with up/rebase-dirty:main (rebase), not pulled, local changes' \
  'github=u1 u2 f1; main=u1 f1; HEAD=main; changes=M shared.txt' \
  'up to date, not pulled, local changes'

# ...with local changes that are gone by run 2, which pulls then
behind rebase-cleaned
clone_fork rebase-cleaned
print local >>$REPOS_DIR/rebase-cleaned/shared.txt
expect rebase-cleaned \
  'synced with up/rebase-cleaned:main (rebase), not pulled, local changes' \
  'github=u1 u2 f1; main=u1 f1; HEAD=main; changes=M shared.txt' \
  'up to date, pulled main in ~/repos/rebase-cleaned' \
  'github=u1 u2 f1; main=github; HEAD=main'

# ...with a commit on the clone's branch that origin never had
behind rebase-ahead
clone_fork rebase-ahead
commit_in $REPOS_DIR/rebase-ahead local local.txt local
expect rebase-ahead \
  'synced with up/rebase-ahead:main (rebase), not pulled, diverged from origin/main' \
  'github=u1 u2 f1; main=u1 f1 local; HEAD=main' \
  'up to date, not pulled, diverged from origin/main'

# No commits of its own: fast-forwarded
new_fork ff
upstream_commit ff u2 upstream.txt u2
clone_fork ff
expect ff \
  'synced with up/ff:main (fast-forward), pulled main in ~/repos/ff' \
  'github=u1 u2; main=github; HEAD=main' \
  'up to date'

# Upstream took the fork's change as a commit of its own: f1 comes out empty and is dropped, which
# leaves the fork at upstream's head
current absorbed
upstream_commit absorbed u2 fork.txt f1
clone_fork absorbed
expect absorbed \
  'synced with up/absorbed:main (rebase), pulled main in ~/repos/absorbed' \
  'github=u1 u2; main=github; HEAD=main' \
  'up to date'

# A conflict: GitHub keeps the fork, and the rebase starts in the clone, which stops on it
conflicting conflict
clone_fork conflict
expect conflict \
  'rebase conflict with up/conflict:main, rebasing in ~/repos/conflict' \
  'github=u1 f1; main=github; HEAD=detached; rebase-merge; changes=UU shared.txt' \
  'rebase conflict with up/conflict:main, rebasing in ~/repos/conflict'

# ...with another branch checked out in the clone
conflicting conflict-other
clone_fork conflict-other
in_clone conflict-other switch -qc other
expect conflict-other \
  'rebase conflict with up/conflict-other:main, not rebased, main not checked out' \
  'github=u1 f1; main=github; HEAD=other' \
  'rebase conflict with up/conflict-other:main, not rebased, main not checked out'

# ...with local changes in the clone
conflicting conflict-dirty
clone_fork conflict-dirty
print local >>$REPOS_DIR/conflict-dirty/shared.txt
expect conflict-dirty \
  'rebase conflict with up/conflict-dirty:main, not rebased, local changes' \
  'github=u1 f1; main=github; HEAD=main; changes=M shared.txt' \
  'rebase conflict with up/conflict-dirty:main, not rebased, local changes'

# ...with the rebase already stopped in the clone, by the other backend (rebase-apply)
conflicting conflict-rebasing
clone_fork conflict-rebasing
in_clone conflict-rebasing fetch -q upstream
in_clone conflict-rebasing rebase -q --apply upstream/main >/dev/null 2>&1
expect conflict-rebasing \
  'rebase conflict with up/conflict-rebasing:main, rebasing in ~/repos/conflict-rebasing' \
  'github=u1 f1; main=github; HEAD=detached; rebase-apply; changes=UU shared.txt' \
  'rebase conflict with up/conflict-rebasing:main, rebasing in ~/repos/conflict-rebasing'

# ...with the rebase finished in the clone, not pushed
conflicting conflict-unpushed
clone_fork conflict-unpushed
rebased_locally conflict-unpushed
expect conflict-unpushed \
  'rebase conflict with up/conflict-unpushed:main, unpushed rebase in ~/repos/conflict-unpushed' \
  'github=u1 f1; main=u1 u2 f1; HEAD=main' \
  'rebase conflict with up/conflict-unpushed:main, unpushed rebase in ~/repos/conflict-unpushed'

# ...finished and not pushed, then upstream moved on again: rebased once more, onto u3
conflicting conflict-moved
clone_fork conflict-moved
rebased_locally conflict-moved
upstream_commit conflict-moved u3 upstream.txt u3
expect conflict-moved \
  'rebase conflict with up/conflict-moved:main, unpushed rebase in ~/repos/conflict-moved' \
  'github=u1 f1; main=u1 u2 u3 f1; HEAD=main' \
  'rebase conflict with up/conflict-moved:main, unpushed rebase in ~/repos/conflict-moved'

# Upstream's new head can't be fetched: its repo is gone since GitHub listed it
behind upstream-gone
clone_fork upstream-gone
pin upstream-gone
rm -rf $root/remote/up/upstream-gone.git
expect upstream-gone \
  "failed, fatal: '$root/remote/up/upstream-gone.git' does not appear to be a git repository" \
  'github=u1 f1; main=github; HEAD=main' \
  "failed, fatal: '$root/remote/up/upstream-gone.git' does not appear to be a git repository"

# The lease: the fork gains f2 after GitHub listed it at f1, so the push is refused. Run 2 lists it
# afresh and syncs it
behind lease
clone_fork lease
pin lease
fork_commit lease f2 fork.txt f2
expect lease \
  'failed, ! [rejected]        <oid> -> main (stale info)' \
  'github=u1 f1 f2; main=u1 f1; HEAD=main' \
  'synced with up/lease:main (rebase), pulled main in ~/repos/lease' \
  'github=u1 u2 f1 f2; main=github; HEAD=main'

# A merge among the fork's own commits, which git replay can't rebase
behind merged
merge_upstream merged
upstream_commit merged u3 upstream.txt u3
clone_fork merged
expect merged \
  'failed, fatal: replaying merge commits is not supported yet!' \
  'github=u1 f1 merge; main=github; HEAD=main' \
  'failed, fatal: replaying merge commits is not supported yet!'

# No clone: cloned, then synced like the rest
behind uncloned
expect uncloned \
  'synced with up/uncloned:main (rebase), cloned to ~/repos/uncloned, pulled main in ~/repos/uncloned' \
  'github=u1 u2 f1; main=github; HEAD=main' \
  'up to date'

# Where the fork's clone would be, a clone of a same-named repo (upstream's): left alone
behind foreign
git clone -q https://github.com/up/foreign.git $REPOS_DIR/foreign
expect foreign \
  "failed, ~/repos/foreign isn't a clone of hareki/foreign" \
  'github=u1 f1; main=u1 u2; HEAD=main' \
  "failed, ~/repos/foreign isn't a clone of hareki/foreign"

# An empty fork, listed with empty lines for its branch. Not last, so the fork after it would shift
# into the wrong fields if those lines got lost
gh_forks+=(empty)
gh_pinned[empty]=$'empty\n\n\nup/empty\n\n'
expect empty 'failed, no commits to sync' 'github=none; clone=none' 'failed, no commits to sync'

# On the ignore list: neither cloned nor fast-forwarded
new_fork eagle.nvim
upstream_commit eagle.nvim u2 upstream.txt u2
expect eagle.nvim 'ignored' 'github=u1; clone=none' 'ignored'

# --- Run 1

# The same in both runs
conflicts='
==> Rebase conflicts, finish them in the clone and force-push, or add the fork to the ignore list:
  https://github.com/hareki/conflict: rebasing in ~/repos/conflict
  https://github.com/hareki/conflict-other: not rebased, main not checked out
  https://github.com/hareki/conflict-dirty: not rebased, local changes
  https://github.com/hareki/conflict-rebasing: rebasing in ~/repos/conflict-rebasing
  https://github.com/hareki/conflict-unpushed: unpushed rebase in ~/repos/conflict-unpushed
  https://github.com/hareki/conflict-moved: unpushed rebase in ~/repos/conflict-moved'

run_sync 1
t_eq 'run 1: exit status' $rc 1
same_lines 'run 1: stdout, a line per fork, the synced forks and the tally' "$(plain $root/1.out)" "$(report 1)

==> Synced with upstream:
  https://github.com/hareki/rebase: pulled main in ~/repos/rebase
  https://github.com/hareki/rebase-other: pulled main in ~/repos/rebase-other
  https://github.com/hareki/rebase-dirty: not pulled, local changes
  https://github.com/hareki/rebase-cleaned: not pulled, local changes
  https://github.com/hareki/rebase-ahead: not pulled, diverged from origin/main
  https://github.com/hareki/ff: pulled main in ~/repos/ff
  https://github.com/hareki/absorbed: pulled main in ~/repos/absorbed
  https://github.com/hareki/uncloned: cloned to ~/repos/uncloned, pulled main in ~/repos/uncloned

==> 8 synced, 1 up to date, 1 ignored, 6 conflicting, 5 failed, 1 cloned, 5 pulled, 3 not pulled, 2 rebasing, 2 unpushed, 2 not rebased"
same_lines 'run 1: stderr, the conflicts, failures and clones not pulled' "$(plain $root/1.err)" "$conflicts

==> Failed to sync:
  upstream-gone: fatal: '$root/remote/up/upstream-gone.git' does not appear to be a git repository
  lease: ! [rejected]        <oid> -> main (stale info)
  merged: fatal: replaying merge commits is not supported yet!
  foreign: ~/repos/foreign isn't a clone of hareki/foreign
  empty: no commits to sync

==> Clones not pulled:
  ~/repos/rebase-dirty: local changes
  ~/repos/rebase-cleaned: local changes
  ~/repos/rebase-ahead: diverged from origin/main"
# Only a side that moved since its clone last saw it costs a fetch
same_lines 'run 1: network use' "$(network 1)" "\
rebase: fetch upstream, push
rebase-other: fetch upstream, push
rebase-dirty: fetch upstream, push
rebase-cleaned: fetch upstream, push
rebase-ahead: fetch upstream, push
ff: fetch upstream, push
absorbed: fetch upstream, push
conflict: fetch upstream
conflict-other: fetch upstream
conflict-dirty: fetch upstream
conflict-moved: fetch upstream
upstream-gone: fetch upstream
lease: fetch upstream, push
merged: fetch upstream
uncloned: clone, fetch upstream, push"

typeset -A after_run1
for n in $gh_forks; do
  t_eq "$n: after run 1" "$(state $n)" "$want_state[1/$n]"
  after_run1[$n]=$(snapshot $n)
done
t_eq 'uncloned: cloned with an SSH origin and an HTTPS upstream' \
  "$(in_clone uncloned config remote.origin.url) $(in_clone uncloned config remote.upstream.url)" \
  'git@gh-personal:hareki/uncloned.git https://github.com/up/uncloned.git'

# --- Run 2, on what run 1 left, but for rebase-cleaned's changes and the lease fork's listing

in_clone rebase-cleaned checkout -q -- shared.txt
unset 'gh_pinned[lease]'

run_sync 2
t_eq 'run 2: exit status' $rc 1
same_lines 'run 2: stdout, a line per fork, the synced forks and the tally' "$(plain $root/2.out)" "$(report 2)

==> Synced with upstream:
  https://github.com/hareki/lease: pulled main in ~/repos/lease

==> 1 synced, 9 up to date, 1 ignored, 6 conflicting, 4 failed, 2 pulled, 2 not pulled, 2 rebasing, 2 unpushed, 2 not rebased"
same_lines 'run 2: stderr, the conflicts, failures and clones not pulled' "$(plain $root/2.err)" "$conflicts

==> Failed to sync:
  upstream-gone: fatal: '$root/remote/up/upstream-gone.git' does not appear to be a git repository
  merged: fatal: replaying merge commits is not supported yet!
  foreign: ~/repos/foreign isn't a clone of hareki/foreign
  empty: no commits to sync

==> Clones not pulled:
  ~/repos/rebase-dirty: local changes
  ~/repos/rebase-ahead: diverged from origin/main"
# Up-to-date forks cost no fetch: only the fork that moved and the failed fetch's retry go out
same_lines 'run 2: network use' "$(network 2)" "\
upstream-gone: fetch upstream
lease: fetch origin, push"

for n in $gh_forks; do
  if (( $+want_state[2/$n] )); then
    t_eq "$n: after run 2" "$(state $n)" "$want_state[2/$n]"
  else
    same_lines "$n: run 2 left it as run 1 did" "$(snapshot $n)" "$after_run1[$n]"
  fi
done

t_done
