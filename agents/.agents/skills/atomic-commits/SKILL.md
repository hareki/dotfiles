---
name: atomic-commits
description: Split the current worktree (staged and unstaged) into a sequence of atomic commits whose messages match the repository's existing conventions, guarding the process with a snapshot so no change is lost or introduced. Invoke explicitly when you want pending work committed as clean, logically separated commits.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*), Bash(git write-tree:*), Bash(git rev-parse:*)
---

# Atomic Commits

Split everything currently in the worktree into a sequence of small, self-contained commits, ordered sensibly, with messages that match how this repo already writes commits. Whether a change is staged or unstaged does not matter: it all gets regrouped here.

Two things must hold when you finish: every pending change ends up committed (nothing lost), and nothing new is committed that was not already in the worktree (nothing invented). The snapshot in step 1 is what lets you prove both at the end, so do not skip it.

## 1. Snapshot the worktree, and capture the full diff in one view

Before grouping anything, record the complete state so you can verify it later and roll back if needed:

```bash
git rev-parse HEAD          # ORIG_HEAD: rollback anchor and end-of-run base
git add -A                  # stage everything: edits, new files, deletions, untracked (ignored files stay out, as they should)
git write-tree              # SNAPSHOT_TREE: the printed SHA is the ground-truth content
git diff --staged HEAD      # the COMPLETE set of pending changes, tracked + untracked, in one place
git reset                   # unstage; this is a mixed reset, it moves only the index and leaves every file untouched
```

Keep `ORIG_HEAD` and `SNAPSHOT_TREE` for step 5. The `git diff --staged HEAD` output above is your full inventory of what needs to be committed, so read it carefully before planning.

## 2. Learn the repo's commit style

```bash
git log -30 --format='%s'                       # subject-line conventions
git log -10 --format='%s%n%n%b%n--------'       # whether/how bodies are used
```

Infer and follow what the repo actually does, not a generic default: Conventional Commits prefixes (`feat`, `fix`, `chore`, `refactor`, `docs`, etc.) and scope notation if present, capitalization, imperative vs. past tense, typical subject length, and whether a body is usually included.

## 3. Plan the commits, then get approval

Group the changes into the smallest set of commits that each represent one coherent concern (one feature, fix, refactor, or cleanup), and order them so each builds on the last (prerequisites and refactors before the features that depend on them).

Present the plan to the user before committing anything: the ordered list of commits, the proposed message for each, and which files (or hunks) go into each. Wait for approval. Do not start committing until the user signs off on the grouping and the order. If they want changes, revise and re-present.

If some changes are too entangled to separate cleanly, say so and propose the best grouping rather than forcing artificial splits.

## 4. Stage and commit each group, in order

For each planned commit:

- Whole files: `git add <file>...`
- A file that spans multiple logical changes: `git add -p <file>` to stage only the relevant hunks. This only ever stages content; it cannot discard it.
- Verify what you are about to commit with `git diff --staged`, then commit with the approved message.

Write the message as exactly the approved content. For a body, pass it as additional `-m` arguments. Add nothing else (see Guardrails on attribution).

## 5. Verify nothing was lost or added

After the final commit:

```bash
git status --short              # must be empty: a clean worktree means everything was committed
git diff <SNAPSHOT_TREE> HEAD   # must print nothing: the committed tree equals the snapshot
```

If `git status` is not clean, a change was missed: stage and commit the remainder (re-running step 1's snapshot view helps you see what is left). If `git diff <SNAPSHOT_TREE> HEAD` shows anything, the committed content diverges from what you started with, so stop and report it rather than papering over it. Both checks passing is the proof that the new commits reproduce exactly the worktree you began with.

If something goes wrong at any point, recover with `git reset --soft <ORIG_HEAD>`: it un-commits everything back into the index without touching a single file, so you can regroup and try again.

## Guardrails

- **No attribution.** Never add a `Co-Authored-By` trailer or any Claude/AI attribution. The message is exactly the approved content, with nothing appended.
- **Commit only what is already there.** Never edit, create, reformat, or delete file contents to make a commit look cleaner. Introduce nothing new into the worktree; the snapshot check in step 5 exists to catch exactly this.
- **Never run change-destroying commands.** `git reset --hard`, `git checkout -- <path>`, `git restore`, `git clean`, and `git stash` can all wipe uncommitted work and are not part of this workflow. The only resets used here are the mixed `git reset` (unstage) and `git reset --soft` (rollback), both of which preserve file content.
- Do not `git push`, `git rebase`, or amend existing commits unless explicitly asked.
- If the worktree is already clean when you start, report that and stop.
