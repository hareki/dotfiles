# Agent Instructions

These instructions apply to every agent and every task.

## General Guidelines

- NEVER use em dashes (—). Use plain dashes, commas, parentheses, or colons instead.
- NEVER remove comments, log statements, or any code unrelated to the current task unless explicitly asked. Treat all existing code as intentional.
- NEVER use "→" for an arrow; use "=>" instead.
- NEVER add excessive code comments when implementing tasks unless explicitly asked. Add a comment only where it explains complex logic or why the code is written this way.
- NEVER use the `AskUserQuestion` tool (it is denied). Ask me questions and offer choices in your chat reply instead. Number the options, show any option that changes code as a full code block, mark the one you recommend with "(Recommended)" and say why, then end your turn and wait for my pick.
- As the main agent, prefer delegating to subagents for work like exploration, research, reading long logs or test output, or reviews, whenever it fits. Delegating keeps your own context window small.
- ALWAYS prewarm the relevant language server with a `documentSymbol` call on the target file before using LSP `findReferences`.
- When I ask you to resolve a merge or rebase conflict, finish the operation, without waiting for my approval. Unless explicitly asked, never push the result.
- When you run as a background session (agents view or `claude --bg`) and change code, work in the isolated worktree and land the work yourself, unless I ask to keep the worktree or open a PR. This overrides the default background-session guidance to push, open a draft PR, and never merge. Land it in this order:
  1. Before EnterWorktree, note the branch checked out in the shared checkout (the one you were spawned from). Call it `<base branch>`.
  2. Do the work in the worktree and commit it there.
  3. In the worktree, run `git rebase <base branch>`.
  4. Call ExitWorktree with `keep`.
  5. In the shared checkout, run `git merge --ff-only <worktree branch>`.
  6. Remove the worktree with `git worktree remove <path>`, then delete its branch with `git branch -d <worktree branch>`.

  Never push, stash, reset, create a merge commit, or use `--force`/`-D`. If the rebase conflicts, the shared checkout is no longer on `<base branch>`, or any git step refuses, stop, keep the worktree, and tell me.

- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
