local PREFIX = 'Coding Agent: '

--- @module 'features.ai.claudecode-nvim.session'
local session = Defer.on_exported_call('features.ai.claudecode-nvim.session')

return {
  UI.which_key({
    specs = { '<leader>a', group = 'Coding Agent', mode = { 'n', 'x' } },
    rules = {
      pattern = 'coding agent',
      icon = Conf.icons.cmp_kinds.CodingAgent,
      color = Conf.icons.colors.CODING_AGENT,
    },
  }),

  -- The panel's Claude session rides in the nvim session, so the next nvim here resumes it
  {
    'auto-session',
    opts = {
      pre_restore_cmds = { session.forget },
      save_extra_data = session.save,
      restore_extra_data = session.restore,
    },
  },

  {
    'hareki/claudecode.nvim',
    cmd = 'ClaudeCode',
    keys = {
      {
        '<A-a>',
        function()
          local terminals = require('core.snacks-nvim.terminals')
          local panel = require('features.ai.claudecode-nvim.panel')

          terminals.hide_others(panel.buf())
          vim.cmd.ClaudeCode()
        end,
        desc = PREFIX .. 'Toggle',
        mode = { 'n', 'x', 't', 'i' },
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeAdd %<cr>',
        desc = PREFIX .. 'Add Current Buffer',
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        desc = PREFIX .. 'Add File',
        ft = { 'NvimTree', 'trouble' },
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeSend<cr>',
        mode = 'x',
        desc = PREFIX .. 'Add Selection',
      },
      {
        '<leader>aa',
        '<cmd>ClaudeCodeDiffAccept<cr>',
        desc = PREFIX .. 'Accept Diff',
      },
      {
        '<leader>ad',
        '<cmd>ClaudeCodeDiffDeny<cr>',
        desc = PREFIX .. 'Deny Diff',
      },
    },

    opts = function()
      local terminals = require('core.snacks-nvim.terminals')

      return {
        -- A function, so the start after an nvim session restore resumes the Claude session
        terminal_cmd = session.command,
        focus_after_send = true,
        terminal = {
          --- @module "snacks"
          --- @type snacks.win.Config | {}
          snacks_win_opts = terminals.win_config({
            title = ' Coding Agent ',
            position = 'float',
          }),
        },
      }
    end,
  },
}
