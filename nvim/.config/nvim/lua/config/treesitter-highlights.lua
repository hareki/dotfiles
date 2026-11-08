--- Treesitter @capture overrides for catppuccin, shared with lazygit's diff renderer so both match
--- Entry point: the renderer dofiles it under --clean, so no config globals or modules (`palette`)
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
