return {
  'kevinhwang91/nvim-hlslens',
  event = 'VeryLazy',
  keys = {
    {
      'n',
      function()
        vim.cmd.normal({ vim.v.count1 .. 'n', bang = true })
        require('hlslens').start()
      end,
      desc = 'Next Search Result',
    },

    {
      'N',
      function()
        vim.cmd.normal({ vim.v.count1 .. 'N', bang = true })
        require('hlslens').start()
      end,
      desc = 'Previous Search Result',
    },
  },
  opts = function()
    return {}
  end,
}
