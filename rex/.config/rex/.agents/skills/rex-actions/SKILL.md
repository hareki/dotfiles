---
name: rex-actions
description: Custom actions in this Rex config (`features/<name>.lua`, `rex.action`), covering how one is filed, named and titled, its errors, and server versus client calls. Use when adding, changing or retitling an action.
---

# Actions

1. Read [`docs/conventions/actions.md`](../../../docs/conventions/actions.md). A key the action binds follows the `rex-keys` skill.
2. Look up every Rex API the action calls before using it: no type definitions cover them.

## Check

1. Check every `title` you wrote or changed word by word against the title-case rule. A capitalized "Under" or "After" is correct, and the lowercase one is the violation.
2. Run the action with `rex do` against a probe session, unless it queues a client action that stays untested live (the `rex-testing` skill).
