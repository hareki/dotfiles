--- Treesitter @capture overrides for catppuccin, shared with lazygit's diff renderer so the two
--- can't drift
--- Entry point: the renderer dofiles this under `nvim --clean` (codediff/lib/bootstrap.lua), so
--- it uses none of this config's globals or modules, hence `palette`
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
