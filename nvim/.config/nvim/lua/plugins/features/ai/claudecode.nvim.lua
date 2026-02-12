return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'ClaudeCode',
  keys = {
    {
      '<M-a>',
      function()
        vim.cmd.ClaudeCode()
      end,
      desc = 'Toggle Claude',
      mode = { 'n', 'x', 't' },
    },
    {
      '<leader>ar',
      function()
        vim.cmd({ cmd = 'ClaudeCode', args = { '--resume' } })
      end,
      desc = 'Resume Claude',
    },
    {
      '<leader>aC',
      function()
        vim.cmd({ cmd = 'ClaudeCode', args = { '--continue' } })
      end,
      desc = 'Continue Claude',
    },
    {
      '<leader>am',
      function()
        vim.cmd.ClaudeCodeSelectModel()
      end,
      desc = 'Select Claude model',
    },
    {
      '<leader>ab',
      function()
        vim.cmd({ cmd = 'ClaudeCodeAdd', args = { vim.fn.expand('%') } })
      end,
      desc = 'Add Current Buffer',
    },
    {
      '<leader>as',
      function()
        vim.cmd.ClaudeCodeSend()
      end,
      mode = 'v',
      desc = 'Send to Claude',
    },
    {
      '<leader>as',
      function()
        vim.cmd.ClaudeCodeTreeAdd()
      end,
      desc = 'Add File',
      ft = { 'NvimTree' },
    },
    {
      '<leader>aa',
      function()
        vim.cmd.ClaudeCodeDiffAccept()
      end,
      desc = 'Accept Diff',
    },
    {
      '<leader>ad',
      function()
        vim.cmd.ClaudeCodeDiffDeny()
      end,
      desc = 'Deny Diff',
    },
  },

  opts = function()
    local size_utils = require('utils.ui')
    local size = size_utils.popup_config('lg')

    return {
      terminal = {
        ---@module "snacks"
        ---@type snacks.win.Config|{}
        snacks_win_opts = {
          title = ' Claude Code ',
          position = 'float',
          width = size.width,
          height = size.height,
          col = size.col,
          row = size.row,
        },
      },
    }
  end,
}
