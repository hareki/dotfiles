return {
  'hareki/eagle.nvim',
  command = 'EagleWin',
  keys = {
    {
      'gh',
      '<cmd>EagleWin<cr>',
      mode = { 'n', 'x' },
      desc = 'Open Eagle Window',
      silent = true,
    },
  },
  opts = function()
    local icons = require('configs.icons')
    return {
      order = 3, -- LSP info comes first
      height_offset = -1,
      keyboard_mode = true,
      mouse_mode = false,
      border = 'rounded',
      show_headers = false,
      source_formatters = {
        ts = function(diagnostic)
          return require('utils.formatters.ts-errors').format(diagnostic, {
            href = false,
          })
        end,
      },
      improved_markdown = {
        replace_dashes = false,
        severity_renderer = {
          ERROR = { icon = icons.diagnostics.Error, hl = 'RenderMarkdownError' },
          WARNING = { icon = icons.diagnostics.Warn, hl = 'RenderMarkdownWarn' },
          INFO = { icon = icons.diagnostics.Info, hl = 'RenderMarkdownInfo' },
          HINT = { icon = icons.diagnostics.Hint, hl = 'RenderMarkdownHint' },
        },
      },
      on_open = function(eagle_win, eagle_buf)
        local current_buf = vim.api.nvim_get_current_buf()
        local current_win = vim.api.nvim_get_current_win()
        local eagle_map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = eagle_buf,
            silent = true,
            desc = desc,
          })
        end

        local current_map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = current_buf,
            silent = true,
            desc = desc,
          })
        end

        local close_eagle = function()
          pcall(vim.api.nvim_win_close, eagle_win, true)
        end

        eagle_map({ 'n', 'x' }, 'q', close_eagle, 'Close eagle')
        eagle_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close eagle')
        eagle_map({ 'n', 'x' }, '<PageUp>', '<C-u>', 'Scroll up')
        eagle_map({ 'n', 'x' }, '<PageDown>', '<C-d>', 'Scroll down')
        eagle_map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.autocmd').noautocmd(function()
            vim.api.nvim_set_current_win(current_win)
          end)
        end, 'Focus parent window')

        current_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close eagle')
        current_map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.autocmd').noautocmd(function()
            vim.api.nvim_set_current_win(eagle_win)
          end)
        end, 'Focus eagle window')
      end,
    }
  end,
}
