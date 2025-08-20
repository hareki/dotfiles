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

        local eagle_opts = function(desc)
          return {
            buffer = eagle_buf,
            silent = true,
            desc = desc,
          }
        end

        local current_opts = function(desc)
          return {
            buffer = current_buf,
            silent = true,
            desc = desc,
          }
        end

        local close_eagle = function()
          pcall(vim.api.nvim_win_close, eagle_win, true)
        end

        local map = vim.keymap.set

        map({ 'n', 'x' }, 'q', close_eagle, eagle_opts('Close eagle'))
        map({ 'n', 'x' }, '<Esc>', close_eagle, eagle_opts('Close eagle'))
        map({ 'n', 'x' }, '<PageUp>', '<C-u>', eagle_opts('Scroll up'))
        map({ 'n', 'x' }, '<PageDown>', '<C-d>', eagle_opts('Scroll down'))
        map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.autocmd').noautocmd(function()
            vim.api.nvim_set_current_win(current_win)
          end)
        end, eagle_opts('Focus parent window'))

        map({ 'n', 'x' }, '<Esc>', close_eagle, current_opts('Close eagle'))
        map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.autocmd').noautocmd(function()
            vim.api.nvim_set_current_win(eagle_win)
          end)
        end, current_opts('Focus eagle window'))
      end,
    }
  end,
}
