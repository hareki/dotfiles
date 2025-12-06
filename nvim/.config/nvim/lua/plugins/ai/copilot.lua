return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
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
