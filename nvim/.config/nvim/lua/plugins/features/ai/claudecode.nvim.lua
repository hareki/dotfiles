return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'ClaudeCode',
  keys = {
    {
      '<M-a>',
      '<cmd>ClaudeCode<cr>',
      desc = 'Toggle Claude',
      mode = { 'n', 'x', 't' },
    },
    {
      '<leader>ar',
      '<cmd>ClaudeCode --resume<cr>',
      desc = 'Resume Claude',
    },
    {
      '<leader>aC',
      '<cmd>ClaudeCode --continue<cr>',
      desc = 'Continue Claude',
    },
    {
      '<leader>am',
      '<cmd>ClaudeCodeSelectModel<cr>',
      desc = 'Select Claude model',
    },
    {
      '<leader>ab',
      '<cmd>ClaudeCodeAdd %<cr>',
      desc = 'Add Current Buffer',
    },
    {
      '<leader>as',
      '<cmd>ClaudeCodeSend<cr>',
      mode = 'v',
      desc = 'Send to Claude',
    },
    {
      '<leader>as',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Add File',
      ft = { 'NvimTree' },
    },
    {
      '<leader>aa',
      '<cmd>ClaudeCodeDiffAccept<cr>',
      desc = 'Accept Diff',
    },
    {
      '<leader>ad',
      '<cmd>ClaudeCodeDiffDeny<cr>',
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
