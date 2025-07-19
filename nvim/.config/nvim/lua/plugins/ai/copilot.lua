return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'BufReadPost',
  opts = {
    -- We use copilot cmp instead
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}
