local PREFIX = 'Coding Agent: '

return {
  UI.which_key({
    specs = { '<leader>a', group = 'Coding Agent', mode = { 'n', 'v' } },
    rules = { pattern = 'coding agent', icon = Conf.icons.cmp_kinds.CodingAgent, color = 'cyan' },
  }),

  {
    'hareki/claudecode.nvim',
    cmd = 'ClaudeCode',
    keys = {
      {
        '<A-a>',
        function()
          local fullscreen_panels = require('core.snacks-nvim.fullscreen-panels')
          local terminal = require('claudecode.terminal')

          fullscreen_panels.hide_others(terminal.get_active_terminal_bufnr())
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
        ft = { 'NvimTree' },
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeSend<cr>',
        mode = 'v',
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
      local fullscreen_panels = require('core.snacks-nvim.fullscreen-panels')

      return {
        focus_after_send = true,
        -- With $TMUX set, Claude's OSC 52 comes DCS-wrapped, which nvim's :terminal paints as text
        env = { TMUX = '' },
        terminal = {
          --- @module "snacks"
          --- @type snacks.win.Config | {}
          snacks_win_opts = fullscreen_panels.win_config({
            title = ' Coding Agent ',
            position = 'float',
          }),
        },
      }
    end,
  },
}
