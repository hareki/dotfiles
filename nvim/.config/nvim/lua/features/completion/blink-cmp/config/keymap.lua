--- @class features.completion.blink-cmp.config.keymap
local M = {}

local ai_cmp_sources = { 'minuet' }

M.default = {
  preset = 'none',
  ['<CR>'] = { 'accept', 'fallback' },
  ['<Tab>'] = { 'snippet_forward', 'fallback' },
  ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

  ['<Up>'] = {
    'select_prev',
    'fallback',
  },
  ['<Down>'] = {
    'select_next',
    'fallback',
  },

  -- No 'fallback': unless the documentation is open, the keys do nothing in insert mode
  ['<PageUp>'] = { 'scroll_documentation_up' },
  ['<PageDown>'] = { 'scroll_documentation_down' },
  ['<Space>'] = {
    function(cmp)
      -- Force reset the completion context when typing too fast
      vim.defer_fn(cmp.hide, 20)
    end,
    'fallback',
  },

  ['<A-Space>'] = {
    function(cmp)
      if cmp.is_menu_visible() then
        return cmp.show({ providers = ai_cmp_sources })
      else
        return cmp.show()
      end
    end,
    'fallback',
  },

  ['<C-Space>'] = {
    function(cmp)
      return cmp.show({ providers = ai_cmp_sources })
    end,
    'fallback',
  },
}

M.cmdline = {
  preset = 'inherit',
  ['<Tab>'] = { 'show', 'select_next', 'fallback' },
  ['<Esc>'] = {
    'hide',
    -- 'fallback' won't cut it because of this bug in neovim
    -- https://github.com/neovim/neovim/issues/21585
    function()
      -- Feed <C-c> to cancel the command line instead
      vim.api.nvim_feedkeys(vim.keycode('<C-c>'), 'n', false)

      return true
    end,
  },
}

return M
