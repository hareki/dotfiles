-- One color per mode (UI.mode), on the cursor line number as on lualine's mode pill
return {
  UI.catppuccin(UI.mode.highlights),

  {
    'mode-colors',
    virtual = true,

    init = function()
      -- ColorScheme relinks after the colorscheme resets CursorLineNr
      vim.api.nvim_create_autocmd({ 'ModeChanged', 'ColorScheme' }, {
        group = vim.api.nvim_create_augroup('chrome.mode-colors.line-number', { clear = true }),
        callback = function()
          local hl_name = UI.mode.group()
          -- Relinking redraws every window, so only relink on a target change
          if vim.api.nvim_get_hl(0, { name = 'CursorLineNr' }).link ~= hl_name then
            vim.api.nvim_set_hl(0, 'CursorLineNr', { link = hl_name })
          end
        end,
      })
    end,
  },
}
