---
name: setup-tonomo-task
description: Set up the Matt Pocock skills for one Tonomo Jira task only, with the docs in a tracked task folder and the instructions in the git-ignored .claude/CLAUDE.md, then route the skills to run next.
disable-model-invocation: true
argument-hint: "[jira-url | jira-key]"
allowed-tools: Read(~/.claude/skills/**), Bash(git branch:*), Bash(git rev-parse:*), Bash(git check-ignore:*), Bash(git status:*), Bash(git add:*), Bash(git commit:*), mcp__plugin_atlassian_atlassian__getJiraIssue, mcp__plugin_atlassian_atlassian__listJiraIssueComments
---

# Setup Tonomo Task

Run `/setup-matt-pocock-skills` **scoped** to one Jira task, so the engineering skills work from the task's own docs and the repo keeps no setup once the PR is up:

- `<KEY>-docs/` holds everything the skills read and write. It's tracked so the user can follow what changes, and the user removes it when creating the PR.
- `.claude/CLAUDE.md` holds the `## Agent skills` block and stays out of git.

Everything outside those two paths stays as it is. `<KEY>` is the Jira key, such as `DEV-1723`.

## 1. Identify the task

Take `<KEY>` from the argument (a Jira URL or key, uppercased), else from the branch name (`hv/DEV-1723-settings-page-layout`), else ask the user.

Read the ticket on `getautonomo.atlassian.net`, using `getJiraIssue` with `view: "evidence"` (the default view omits links) and `listJiraIssueComments`. Open each issue its links or description point to, far enough to know what that issue owns. If Jira can't be reached, ask the user what the task covers.

Then read what the tree already holds:

- `<KEY>-docs/`, if it has content. The setup builds around those docs.
- Every other `*-docs/` folder at the repo root. These are the **related docs**: task folders leave the tree when their PR is created, so one that's still here is the parent epic's docs or, for any other key, a task this branch stacks on.
- `docs/GLOSSARY.md`, the repo-wide glossary, in the repos that have one.

Done when you can name the task in a few words, in the glossaries' terms, and say which parts of any related docs bear on it and what the ticket and those docs state about how it ships.

## 2. Load the setup

Read [`setup-matt-pocock-skills/SKILL.md`](../setup-matt-pocock-skills/SKILL.md) and the seeds beside it: `issue-tracker-local.md`, `triage-labels.md`, and `domain.md`. It's user-invoked, so read the files rather than calling it as a skill.

It defines the outputs. The steps here replace its process, and the baseline commit gives the user a diff to review in place of its draft-and-confirm step. Its choices are settled:

- **Issue tracker**: local markdown in `<KEY>-docs/`.
- **Triage labels**: the defaults.
- **Domain docs**: single-context, scoped to the task.
- **Output paths**: `<KEY>-docs/agents/` in place of `docs/agents/`, and `.claude/CLAUDE.md` in place of the root `CLAUDE.md` / `AGENTS.md`.

If it has grown an output or a question these answers don't cover, scope that to the task the same way and mention it in the report.

## 3. Write `<KEY>-docs/agents/`

Build each file from its seed, tuned to this task. `SPEC.md`, `MAP.md`, `GLOSSARY.md`, `ADR.md`, and `issues/` stay unwritten: the skills that use them create them.

**`issue-tracker.md`** (seed: `issue-tracker-local.md`)

- Point every `.scratch/` path at `<KEY>-docs/`, with no slug directory below it: the task is the one directory. The spec is `SPEC.md`, the map is `MAP.md`, and tickets stay in `issues/`.
- Replace the intro: the spec and tickets for the task live as markdown files in `<KEY>-docs/`, beside the task's other docs, and `<KEY>` stays the only Jira issue for them.
- Add these conventions:
  - These paths win over any default path a skill names for local tickets.
  - A finished ticket gets `Status: done`.
  - A done ticket records what was built, so its description and criteria aren't rewritten afterwards, though a criterion checked by hand later can still be ticked. When later work changes what it built, add a dated line under its `## Comments` that points to the ticket making the change.
  - An unbuilt ticket is edited in place. A change to built behavior gets a new ticket that names the built ticket and says what changes.
  - `SPEC.md` describes the target, so it can be ahead of the code until its tickets are done.
- Add a convention for what the ticket or related docs state about shipping and boundaries: how many PRs, what the task stacks on or waits for, and which pieces another Jira issue owns, so they get no ticket here. What they leave open goes in the report instead.

**`triage-labels.md`** (seed: same name)

Keep the default table. Reword the prose around it for a local tracker: the strings go on each ticket's `Status:` line, and the closing invitation to edit the column goes.

**`domain.md`** (seed: same name)

- Replace the intro: how the engineering skills consume `<KEY>`'s domain documentation, in one context scoped to this task, with the files in `<KEY>-docs/` in place of a root `GLOSSARY.md` and `docs/adr/`.
- Build "Before exploring, read these" from step 1: the related-doc files that bear on this task, each with a line on what it holds for this task, naming sections where that helps, then `docs/GLOSSARY.md` when it exists, then `<KEY>-docs/GLOSSARY.md` and `<KEY>-docs/ADR.md`. Keep the proceed-silently rule for all of them, since related docs can leave the tree later.
- Replace "File structure" with a "Where new entries go" section:
  - A resolved term goes into `<KEY>-docs/GLOSSARY.md`, in `/domain-modeling`'s glossary format. `docs/GLOSSARY.md` stays read-only for this task.
  - A new decision becomes the next `## ADR-n: <title>` section in `<KEY>-docs/ADR.md`, with a status line (`**Status**: accepted, <date>.`), plus `### Considered options` and `### Consequences` when they add value. This replaces the `docs/adr/NNNN-slug.md` files `/domain-modeling` describes.
  - An amended decision is updated in place, in the file that holds it, and its status line records the amendment (`Amended <date>: <what changed>.`).
  - With related docs on the tree, add: a term a related doc defines stays there. With a related `ADR.md`, add: both files number from ADR-1, so its decisions are always cited with their file, as in `DEV-1689-docs/ADR.md`, ADR-1.
- Reword the remaining sections for tickets and for however many glossaries the list names, and change the `ADR-0007` example to `ADR-n`.

Done when no `.scratch/` path or bare `docs/agents/` path remains in the three files, and every file in "Before exploring" exists on this tree, apart from `<KEY>-docs/GLOSSARY.md` and `<KEY>-docs/ADR.md`.

## 4. Add the block to `.claude/CLAUDE.md`

Run `git check-ignore -q .claude/CLAUDE.md`. If it fails, append `**/.claude/CLAUDE.md` to `$(git rev-parse --git-common-dir)/info/exclude`, which every worktree shares and which stays local. Done when the check passes.

Add this block, or update an existing one in place, keeping the rest of the file:

```markdown
## Agent skills

Scoped to <KEY> (<the task in a few words>) on this branch only: when `<KEY>-docs/` isn't on the tree, this section doesn't apply. `<KEY>-docs/` is working material that's removed when the PR is created, so reviews leave it out.

### Issue tracker

Local markdown in `<KEY>-docs/` (spec in `SPEC.md`, tickets in `issues/`); <KEY> stays the only Jira issue. See `<KEY>-docs/agents/issue-tracker.md`.

### Triage labels

The five default role strings, written on each ticket's `Status:` line. See `<KEY>-docs/agents/triage-labels.md`.

### Domain docs

Single-context, scoped to the task: `<KEY>-docs/GLOSSARY.md` and `<KEY>-docs/ADR.md`, plus <the related docs and `docs/GLOSSARY.md`, whichever exist>. See `<KEY>-docs/agents/domain.md`.
```

## 5. Commit the baseline

Stage `<KEY>-docs/agents/` alone and commit it as `docs(<KEY>): setup mattpocock skills`. The docs change throughout the task, and this commit is what those diffs read against.

If the branch name doesn't carry `<KEY>`, the task's branch isn't checked out: leave the commit to the user and say so in the report.

## 6. Route the next skills

Read [`ask-matt/SKILL.md`](../ask-matt/SKILL.md) and the [`PHASE-BOUNDARIES.md`](../ask-matt/PHASE-BOUNDARIES.md) beside it (user-invoked too, so read them as in step 2), and ask it about this task: the situation is what step 1 found, and the precondition it names is this setup, now done.

- Start where the task stands: when `<KEY>-docs/` already holds a spec or tickets, the route picks up after them, such as at the first ticket not `Status: done`.
- Give each skill on the route a line on what it does for this task, in the glossaries' terms and with `<KEY>-docs/` paths in place of `.scratch/` ones.
- Where ask-matt offers a choice, such as `/implement` per ticket or `/implement-spec`, recommend one from what step 1 found about how the task ships, and name the other.
- Make the context call at every boundary with the PHASE-BOUNDARIES.md tree. The first is `/clear`, because `.claude/CLAUDE.md` is read at session start.

Done when the route runs from the next skill through `/retro`, you've read the SKILL.md of every skill on it, and every boundary names one of the five options with its reason.

## 7. Report

State what was written and the commit, then add:

- What was tuned beyond the seeds: the related docs, and any convention added for this task.
- Anything the ticket and related docs disagree on, which one you followed, and what they leave open.
- The route from step 6 as a numbered list, each item giving the context call and its reason, then the skill and its line.
