---@class blink-cmp.config.keymap
local M = {}

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

  ['<PageUp>'] = {
    function(cmp)
      if cmp.is_documentation_visible() then
        cmp.scroll_documentation_up(4)
      end

      return true
    end,
  },
  ['<PageDown>'] = {
    function(cmp)
      if cmp.is_documentation_visible() then
        cmp.scroll_documentation_down(4)
      end

      return true
    end,
  },
  ['<Space>'] = {
    function(cmp)
      -- Force reset the completion context when typing too fast
      vim.defer_fn(function()
        cmp.hide()
      end, 20)
    end,
    'fallback',
  },

  ['<A-Space>'] = {
    function(cmp)
      if cmp.is_menu_visible() then
        return cmp.show({ providers = { 'copilot' } })
      else
        return cmp.show()
      end
    end,
    'fallback',
  },
}

M.cmdline = {
  preset = 'inherit',
  ['<Esc>'] = {
    function(cmp)
      if cmp.is_menu_visible() then
        cmp.hide()

        return true
      end
    end,
    -- 'fallback' won't cut it because of this bug in neovim
    -- https://github.com/neovim/neovim/issues/21585
    function()
      -- Feed <C-c> to cancel the command line instead
      local keys = vim.api.nvim_replace_termcodes('<C-c>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'n', false)

      return true
    end,
  },
}

return M
