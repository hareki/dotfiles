# Simple Mermaid Example

A basic flowchart showing a login flow.

```mermaid
flowchart TD
    A[User visits site] --> B{Logged in?}
    B -->|Yes| C[Show dashboard]
    B -->|No| D[Show login form]
    D --> E[User submits credentials]
    E --> F{Valid?}
    F -->|Yes| C
    F -->|No| G[Show error]
    G --> D
```

## Notes

- Render this on GitHub, GitLab, or any Markdown viewer that supports Mermaid.
- Change `flowchart TD` to `flowchart LR` for a left-to-right layout.
