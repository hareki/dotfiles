return {
  Catppuccin(function(palette)
    local handle_bg = palette.surface1
    local groups = {
      ScrollbarHandle = { bg = handle_bg },
      ScrollbarMisc = { bg = palette.text },
      ScrollbarMiscHandle = { fg = palette.text, bg = handle_bg },
    }

    for _, item in ipairs({
      { 'Search', palette.mauve },
      { 'Info', palette.sky },
      { 'Hint', palette.teal },
      { 'Warn', palette.yellow },
      { 'Error', palette.red },
    }) do
      local name, color = item[1], item[2]
      groups['Scrollbar' .. name] = { fg = color }
      groups['Scrollbar' .. name .. 'Handle'] = { fg = color, bg = handle_bg }
    end

    return groups
  end),

  {
    'petertriho/nvim-scrollbar',
    lazy = false,
    priority = Priority.CHROME,
    opts = {
      set_highlights = false,
      handle = { blend = 0 },
      handlers = {
        cursor = false,
        diagnostic = true,
        gitsigns = false, -- Requires gitsigns.nvim
        handle = true,
        search = true, -- Requires nvim-hlslens
        ale = false,
      },
    },
  },
}
