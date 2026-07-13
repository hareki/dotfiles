local prefix = 'Coding Agent: '

return {
  UI.which_key({
    specs = { '<leader>a', group = 'Coding Agent', mode = { 'n', 'v' } },
    rules = { pattern = 'coding agent', icon = Conf.icons.cmp_kinds.CodingAgent, color = 'cyan' },
  }),

  {
    'coder/claudecode.nvim',
    -- TODO: remove this when the focus management is fixed
    commit = '102d835c964069c9c5e37abaf05ae4f9c3ee6f00',
    cmd = 'ClaudeCode',
    dependencies = { 'hareki/snacks.nvim' },
    keys = {
      {
        '<A-a>',
        '<cmd>ClaudeCode<cr>',
        desc = prefix .. 'Toggle',
        mode = { 'n', 'x', 't', 'i' },
      },
      {
        '<leader>as',
        '<cmd>ClaudeCodeAdd %<cr>',
        desc = prefix .. 'Add Current Buffer',
      },
      {
        '<leader>as',
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
      local size = UI.layout.popup('full')

      return {
        terminal = {
          --- @module "snacks"
          --- @type snacks.win.Config | {}
          snacks_win_opts = {
            title = ' Coding Agent ',
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
