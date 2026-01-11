return {
  require('utils.ui').catppuccin(function()
    return {
      SidekickDiffAdd = { link = 'DiffAdd' },
    }
  end),
  {
    'folke/sidekick.nvim',
    opts = {},
    dependencies = { 'zbirenbaum/copilot.lua' },
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
    keys = function()
      return {
        {
          '<Tab>',
          expr = true,
          desc = 'Goto/Apply Next Edit Suggestion',
          function()
            if not require('sidekick').nes_jump_or_apply() then
              return '<Tab>' -- Fallback to normal tab
            end
          end,
        },
      }
    end,
  },
}
