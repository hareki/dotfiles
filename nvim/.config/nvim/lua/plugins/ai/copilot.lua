return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'VeryLazy',
  dependencies = { 'folke/sidekick.nvim' },
  opts = function()
    return {
      nes = { enabled = false },
      panel = { enabled = false },
      suggestion = {
        enabled = false,
        auto_trigger = false,
        hide_during_completion = true,
      },
      filetypes = {
        markdown = true,
        help = true,
      },
    }
  end,
}
