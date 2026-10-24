--- Treesitter @capture overrides, shared with the lazygit codediff renderer so the two can't
--- drift; it loads them in a headless `nvim --clean` with no UI/Conf globals, hence `palette`
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
