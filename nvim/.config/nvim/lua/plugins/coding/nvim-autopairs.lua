return {
  'windwp/nvim-autopairs',
  event = 'VeryLazy',
  opts = function()
    return {
      disable_filetype = { 'TelescopePrompt', 'vim', 'snacks_picker_input' },
      -- https://github.com/windwp/nvim-autopairs?tab=readme-ov-file#treesitter
      check_ts = true,
      ts_config = {
        lua = { 'string' },
        javascript = { 'template_string' },
        java = false,
      },
    }
  end,
}
