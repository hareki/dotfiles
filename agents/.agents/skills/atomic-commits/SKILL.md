---
name: atomic-commits
description: Analyze the dirty worktree and split it into atomic commits, matching the repo's existing commit message style. Use when the user asks to commit pending changes, split work into commits, or wants clean/atomic commit history.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git reset:*)
---

# Atomic Commit

Split the current dirty worktree into a sequence of atomic commits whose messages match the repository's existing conventions.

## Steps

1. **Inspect the working tree.** Run the following to understand what changed:
   - `git status --short`
   - `git diff` (unstaged) and `git diff --staged` (already staged)

2. **Learn the commit message style.** Run:
   - `git log -30 --format='%s'` to see subject-line conventions
   - `git log -10 --format='%s%n%n%b%n--------'` to see whether bodies are used and how they're formatted

   Infer and follow: Conventional Commits prefixes (`feat:`, `fix:`, etc.) if present, capitalization, imperative vs. past tense, subject length, scope notation, and whether a body is typically included. Match what the repo actually does, not a generic default.

3. **Plan the commits.** Group the changes into the smallest set of self-contained, logically independent commits. Each commit should:
   - Represent one coherent change (one feature, fix, refactor, or concern)
   - Build / pass on its own where reasonable
   - Not mix unrelated changes

   Present the plan to the user (commit order + proposed message for each) before committing.

4. **Stage and commit each group in order.** Stage selectively per commit:
   - Whole files: `git add <file>...`
   - Partial files: `git add -p <file>` (split hunks when a single file spans multiple logical changes)

   Then commit. Verify staging with `git diff --staged` before each commit.

## Constraints

- **Never add a `Co-Authored-By: Claude` trailer or any Claude attribution** to commit messages. Write the message exactly as the final content, with nothing appended.
- Do not run `git push`.
- Do not amend or rebase existing commits unless explicitly asked.
- If nothing is staged and the worktree is clean, report that and stop.
- If changes are too entangled to separate cleanly, say so and propose the best grouping rather than forcing artificial splits.
