---
name: nvim-ui
description: UI rules for this Neovim config, covering icons, colors, highlight groups, and float, picker and window sizing. Use when adding or changing an icon, a color or highlight, a floating window or a Snacks picker layout.
---

# UI

## Icons and colors

- Take every icon from `config/icons.lua` (`Conf.icons`), never a literal glyph string.
- Name a color by its Catppuccin palette key (`teal`, `mauve`, `peach`; the `PaletteKey` alias in `utils/ui/catppuccin-nvim.lua` lists them). An icon that more than one surface paints (a which-key rule, a statusline piece, a winbar title, a picker label) takes its color from `Conf.icons.colors`, so the surfaces agree.
- A plugin's highlights are registered from its spec file with `UI.catppuccin(...)` (the `nvim-plugin-specs` skill); `UI.catppuccin.get_palette('ext')` gives the config's extra colors.

## Float sizing

Size floats through `UI.layout` (`utils/ui/layout.lua`, whose annotations document each helper), never hardcoded dimensions. A float sized to its content stays within the `inline_max_height`/`inline_max_width` caps, and only a cursor-anchored popup (`features/diagnostics/hl-at-cursor/utils.lua`) places itself, since `UI.layout` has no cursor-relative placement.

- Prefer the function-valued helpers (`float_fn`, `picker_fn`, the caps) wherever the consumer accepts callables, so sizes follow terminal resizes
- A float's `zindex` comes from the `Conf.zindex` ladder (`config/zindex.lua`)
