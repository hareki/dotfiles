--- Treesitter @capture overrides, shared by the editor's catppuccin setup and
--- the lazygit codediff renderer. The renderer bootstraps catppuccin in a
--- headless `nvim --clean` and reads these groups back out of the live
--- colorscheme, so a diff drawn in lazygit only matches the one nvim draws
--- while both sides hold the same overrides -- keeping them here is what stops
--- the two from drifting.
---
--- Takes the palette rather than reaching for one: `--clean` never loads the
--- editor's UI/Conf globals, so the renderer has nothing to resolve it with.
--- @param palette table catppuccin palette for the active flavour
--- @return table<string, table>
return function(palette)
  return {
    ['@string.special.path'] = { fg = palette.text },
    ['@markup.quote'] = { fg = palette.text },
    ['@markup.italic'] = { fg = palette.flamingo, italic = true },
    ['@markup.strong'] = { fg = palette.flamingo, bold = true },
  }
end
