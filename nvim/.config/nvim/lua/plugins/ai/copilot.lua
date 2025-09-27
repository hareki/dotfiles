return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'BlinkCmpMenuOpen',
      callback = function()
        vim.b.copilot_suggestion_hidden = true
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = 'BlinkCmpMenuClose',
      callback = function()
        vim.b.copilot_suggestion_hidden = false
      end,
    })

    return {
      suggestion = {
        enabled = false,

        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = '<Tab>',
          accept_word = '<S-Tab>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = false,
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    }
  end,
}
