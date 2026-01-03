return {
  'wurli/visimatch.nvim',
  opts = function()
    return {
      chars_lower_limit = 2,
      hl_group = 'DocumentHighlight',
    }
  end,
  init = function()
    -- Load the plugin only when entering visual mode
    vim.api.nvim_create_autocmd('ModeChanged', {
      desc = 'Load Visimatch in Visual Mode',
      pattern = { '*:v', '*:V' }, -- v, V, <C-v>
      once = true,
      callback = function()
        require('lazy').load({ plugins = { 'visimatch.nvim' } })
      end,
    })
  end,
}
