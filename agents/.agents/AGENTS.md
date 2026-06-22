# Agent Instructions

These are common instructions for agents across all scenarios

## General Guidelines

- NEVER use em dashes (—), consider using plain dashes, commas, parentheses, or colons instead.
- NEVER remove comments, log statements, or any code unrelated to the current task unless explicitly asked. Treat all existing code as intentional.
- NEVER auto-add your agent name as co-author when writing commit messages.
- NEVER use "→" when you want to represent the arrow symbol, use "=>" instead.
- NEVER add excessive comments when implementing tasks unless being explicitly asked, only SELECTIVELY add comments that are necessary to explain complex logic or to answer the 'WHY' question.
- NEVER use `AskUserQuestion` tool when representing options that include code changes preview. The terminal UI truncates code previews, making it impossible to evaluate the differences. Instead, show each option as a full code block in the chat output and ask me to choose by number. `AskUserQuestion` tool is fine for options that don't involve code changes.
- ALWAYS prewarm the relevant language server first with a documentSymbol call on the target file first if you want to use LSP `findReferences`.
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
