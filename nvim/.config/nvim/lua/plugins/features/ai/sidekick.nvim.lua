return {
  Catppuccin(function()
    return {
      SidekickDiffAdd = { link = 'DiffAdd' },
    }
  end),

  {
    'folke/sidekick.nvim',
    enabled = true,
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
    opts = {
      nes = { enabled = true },
    },
  },
}
