return {
  'wurli/visimatch.nvim',
  opts = {
    chars_lower_limit = 2,
    hl_group = 'DocumentHighlight',
  },
  init = function()
    -- Load the plugin only when entering visual mode
    vim.api.nvim_create_autocmd('ModeChanged', {
      pattern = { '*:v', '*:V', '*:\x16' }, -- v, V, <C-v>
      once = true,
      callback = function()
        require('lazy').load({ plugins = { 'visimatch.nvim' } })
      end,
    })
  end,
}
