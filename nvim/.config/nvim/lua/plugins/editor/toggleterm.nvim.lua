return {
  'akinsho/toggleterm.nvim',
  cmd = { 'ToggleTerm', 'TermNew', 'TermSelect' },
  keys = {
    {
      '<leader>fe',
      '<CMD>TermSelect<CR>',
    },
    {
      '<leader>en',
      '<CMD>TermNew direction=tab<CR>',
    },
  },
  opts = function()
    local default_highlights = {}
    for _, v in ipairs({
      'Normal',
      'Winbar',
      'WinbarNC',
      'SignColumn',
      'StatusLine',
      'EndOfBuffer',
      'FloatBorder',
    }) do
      default_highlights[v] = {
        link = v,
      }
    end
    return {
      highlights = default_highlights,
      on_open = function(term)
        vim.keymap.set(
          't',
          '<Esc><Esc>',
          '<C-\\><C-n>',
          { desc = 'Leave Terminal Mode', silent = true, buffer = term.bufnr }
        )
      end,
    }
  end,
}
