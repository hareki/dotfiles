return {
  'hareki/eagle.nvim',
  cmd = { 'EagleWin', 'EagleWinLineDiagnostic' },
  opts = function()
    local size_configs = require('configs.size')
    local max_size = size_configs.inline_popup.max_height

    return {
      order = 3, -- LSP info comes first
      border = 'rounded',
      keyboard_mode = true,
      mouse_mode = false,
      show_headers = false,

      get_max_height = function()
        return math.floor(vim.o.lines * max_size)
      end,
      get_max_width = function()
        return math.floor(vim.o.columns * max_size)
      end,

      ---@param diagnostic vim.Diagnostic
      diagnostic_filter = function(diagnostic)
        return diagnostic.source ~= 'underline-hack'
      end,

      source_formatters = {
        ts = function(diagnostic)
          local ts_errors = require('utils.formatters.ts-errors')
          return ts_errors.format(diagnostic, {
            href = false,
          })
        end,
      },

      improved_markdown = {
        replace_dashes = false,
        severity_renderer = {
          ERROR = { icon = Icons.diagnostics.Error, hl = 'RenderMarkdownError' },
          WARNING = { icon = Icons.diagnostics.Warn, hl = 'RenderMarkdownWarn' },
          INFO = { icon = Icons.diagnostics.Info, hl = 'RenderMarkdownInfo' },
          HINT = { icon = Icons.diagnostics.Hint, hl = 'RenderMarkdownHint' },
        },
      },

      on_open = function(eagle_win, eagle_buf)
        local current_buf = vim.api.nvim_get_current_buf()
        local current_win = vim.api.nvim_get_current_win()

        local function eagle_map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = eagle_buf,
            desc = desc,
          })
        end

        local function current_map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = current_buf,
            desc = desc,
          })
        end

        local function current_unmap(mode, lhs)
          pcall(function()
            vim.keymap.del(mode, lhs, { buffer = current_buf })
          end)
        end

        local function close_eagle()
          pcall(vim.api.nvim_win_close, eagle_win, true)
        end

        vim.api.nvim_create_autocmd('WinClosed', {
          pattern = tostring(eagle_win),
          once = true,
          callback = function()
            current_unmap({ 'n', 'x' }, '<Esc>')
            current_unmap({ 'n', 'x' }, '<Tab>')
          end,
        })

        eagle_map({ 'n', 'x' }, 'q', close_eagle, 'Close Eagle')
        eagle_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close Eagle')
        eagle_map({ 'n', 'x' }, '<PageUp>', '<C-u>', 'Scroll Up')
        eagle_map({ 'n', 'x' }, '<PageDown>', '<C-d>', 'Scroll Down')
        eagle_map({ 'n', 'x' }, '<Tab>', function()
          local eagle = require('eagle')
          eagle.ignore_cursor_moved = true
          local common = require('utils.common')
          common.focus_win(current_win)
        end, 'Focus Parent Window')

        current_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close Eagle')
        current_map({ 'n', 'x' }, '<Tab>', function()
          local eagle = require('eagle')
          eagle.ignore_cursor_moved = true
          local common = require('utils.common')
          common.focus_win(eagle_win)
        end, 'Focus Eagle Window')
      end,
    }
  end,
}
