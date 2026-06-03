local prefix = 'Claude Code: '

return {
  WhichKey({
    specs = { '<leader>a', group = 'Claude Code', mode = { 'n', 'v' } },
    rules = { pattern = 'claude', icon = Icons.kinds.Claude, color = 'orange' },
  }),

  {
    'coder/claudecode.nvim',
    dependencies = { 'hareki/snacks.nvim' },
    cmd = 'ClaudeCode',
    keys = {
      {
        '<M-a>',
        '<cmd>ClaudeCode<cr>',
        desc = prefix .. 'Toggle',
        mode = { 'n', 'x', 't' },
      },
      {
        '<leader>ar',
        '<cmd>ClaudeCode --resume<cr>',
        desc = prefix .. 'Resume',
      },
      {
        '<leader>aC',
        '<cmd>ClaudeCode --continue<cr>',
        desc = prefix .. 'Continue',
      },
      {
        '<leader>am',
        '<cmd>ClaudeCodeSelectModel<cr>',
        desc = prefix .. 'Select Model',
      },
      {
        '<leader>ab',
        '<cmd>ClaudeCodeAdd %<cr>',
        desc = prefix .. 'Add Current Buffer',
      },
      {
        '<leader>ab',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = prefix .. 'Add File',
        ft = { 'NvimTree' },
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeSend<cr>',
        mode = 'v',
        desc = prefix .. 'Add Selection',
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = prefix .. 'Add File',
        ft = { 'NvimTree' },
      },
      {
        '<leader>aa',
        '<cmd>ClaudeCodeDiffAccept<cr>',
        desc = prefix .. 'Accept Diff',
      },
      {
        '<leader>ad',
        '<cmd>ClaudeCodeDiffDeny<cr>',
        desc = prefix .. 'Deny Diff',
      },
    },

    opts = function()
      local size_utils = require('utils.ui')
      local size = size_utils.popup_config('full')

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
  },
}
