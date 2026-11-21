# Agent Instructions

These instructions apply to every agent and every task.

## General Guidelines

- NEVER use em dashes (—). Use plain dashes, commas, parentheses, or colons instead.
- NEVER remove comments, log statements, or any code unrelated to the current task unless explicitly asked. Treat all existing code as intentional.
- NEVER use "→" for an arrow; use "=>" instead.
- NEVER add excessive code comments when implementing tasks unless explicitly asked. Add a comment only where it explains complex logic or why the code is written this way.
- NEVER use the `AskUserQuestion` tool (it is denied). Ask me questions and offer choices in your chat reply instead. Number the options, show any option that changes code as a full code block, mark the one you recommend with "(Recommended)" and say why, then end your turn and wait for my pick.
- Prefer delegating to subagents for work like exploration, research, reading long logs or test output, or reviews, whenever it fits. Delegating keeps your own context window small.
- ALWAYS prewarm the relevant language server with a `documentSymbol` call on the target file before using LSP `findReferences`.
- When I ask you to resolve a merge or rebase conflict, finish the operation, without waiting for my approval. Unless explicitly asked, never push the result.
- When you run as a background session (agents view or `claude --bg`) and change code, keep working in the isolated worktree, but land the work yourself unless I ask to keep the worktree or open a PR: before EnterWorktree, note the branch checked out in the shared checkout (the one you were spawned from); when done, commit in the worktree and `git rebase <that branch>` there, then ExitWorktree with `keep`, run `git merge --ff-only <worktree branch>` in the shared checkout, and delete the worktree with `git worktree remove <path>` followed by `git branch -d <worktree branch>`. Never push, stash, reset, create a merge commit, or use `--force`/`-D`; if the rebase conflicts, the shared checkout is no longer on that branch, or any git step refuses, stop, keep the worktree, and tell me. This overrides the default background-session guidance to push, open a draft PR, and never merge.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long-term maintainability.
