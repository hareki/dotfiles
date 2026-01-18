-- Only for Next Edit Suggestion
return {
  require('utils.ui').catppuccin(function()
    return {
      SidekickDiffAdd = { link = 'DiffAdd' },
    }
  end),
  {
    'folke/sidekick.nvim',
    keys = function()
      return {
        {
          '<Tab>',
          function()
            if not require('sidekick').nes_jump_or_apply() then
              return '<Tab>' -- Fallback to normal tab
            end
          end,
          mode = { 'n', 'x' },
          desc = 'Goto/Apply Next Edit Suggestion',
          expr = true,
        },
      }
    end,
    opts = {},
  },
}
