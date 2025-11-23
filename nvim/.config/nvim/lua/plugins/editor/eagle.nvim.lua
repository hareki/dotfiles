return {
  'hareki/eagle.nvim',
  cmd = { 'EagleWin', 'EagleWinLineDiagnostic' },
  opts = function()
    local icons = require('configs.icons')
    local max_size = require('configs.size').inline_popup.max_height
    return {
      order = 3, -- LSP info comes first
      get_max_height = function()
        return math.floor(vim.opt.lines:get() * max_size)
      end,
      get_max_width = function()
        return math.floor(vim.opt.columns:get() * max_size)
      end,
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
      --- @param diagnostic vim.Diagnostic
      diagnostic_filter = function(diagnostic)
        return diagnostic.source ~= 'underline-hack'
      end,

      on_open = function(eagle_win, eagle_buf)
        local current_buf = vim.api.nvim_get_current_buf()
        local current_win = vim.api.nvim_get_current_win()

        local function eagle_map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = eagle_buf,
            silent = true,
            desc = desc,
          })
        end

        local function current_map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = current_buf,
            silent = true,
            desc = desc,
          })
        end

        local function current_unmap(mode, lhs, desc)
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
            current_unmap({ 'n', 'x' }, '<Esc>', 'Close Eagle')
            current_unmap({ 'n', 'x' }, '<Tab>', 'Focus Eagle Window')
          end,
        })

        eagle_map({ 'n', 'x' }, 'q', close_eagle, 'Close Eagle')
        eagle_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close Eagle')
        eagle_map({ 'n', 'x' }, '<PageUp>', '<C-u>', 'Scroll Up')
        eagle_map({ 'n', 'x' }, '<PageDown>', '<C-d>', 'Scroll Down')
        eagle_map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.common').focus_win(current_win)
        end, 'Focus Parent Window')

        current_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close Eagle')
        current_map({ 'n', 'x' }, '<Tab>', function()
          require('eagle').ignore_cursor_moved = true
          require('utils.common').focus_win(eagle_win)
        end, 'Focus Eagle Window')
      end,
    }
  end,
}
