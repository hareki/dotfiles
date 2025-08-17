return {
  'nvim-telescope/telescope-ui-select.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  init = function()
    local select_original = vim.ui.select
    vim.ui.select = function(...)
      local before = vim.ui.select
      local telescope = require('telescope')
      require('lazy').load({ plugins = { 'telescope-ui-select.nvim' } })

      telescope.load_extension('ui-select')

      local after = vim.ui.select
      if after == before then
        after = select_original
      end
      return after(...)
    end
  end,
}
