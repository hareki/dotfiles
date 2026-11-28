# Code style

The Lua rules every file in this config follows. Run `stylua .` after an edit.

- **Requires**: Rex's `package.path` is this directory alone, so modules sit at its root with no `lua/` dir (`require('config.settings')`). Assign a require to a local before use: `local settings = require('config.settings')`, never `require('config.settings')[1]`
- **String formatting**: use `string.format(...)`, never the method form `('...'):format(...)`
- **Constants**: a file-level local holding data the file never reassigns or mutates (lookup tables, lists, fixed strings) is `UPPER_SNAKE` (`TERMINAL`, `NAVIGATION_KEYS`, `THEME`); functions and requires stay `snake_case`
- **Sections**: group a file's bindings or settings under `-- [[ Name ]]` headers
- **File names**: `kebab-case`, dot-free, since `require` reads a `.` as a path separator. A feature file is named with a noun phrase for what it adds (`pane-navigation.lua`), not the verb of its action (`close-pane.lua`). The theme file keeps its exact name: Rex names the imported theme after it ([Theme](settings.md#theme))
