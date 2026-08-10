--- @module 'eagle'
local eagle = Defer.on_exported_call('eagle')

--- @module 'utils.common'
local common = Defer.on_exported_call('utils.common')

return {
  {
    'hareki/eagle.nvim',
    cmd = { 'EagleWin', 'EagleWinLineDiagnostic' },
    opts = function()
      local max_size = Conf.size.inline_popup.MAX_HEIGHT

      return {
        order = 3, -- LSP info comes first
        show_headers = false,
        keyboard = { enabled = true },
        mouse = { enabled = false },

        window = {
          border = 'rounded',
          max_height = function()
            return math.floor(vim.o.lines * max_size)
          end,
          max_width = function()
            return math.floor(vim.o.columns * max_size)
          end,
        },

        source_formatters = {
          ts = function(diagnostic)
            local ts_errors = require('features.diagnostics.eagle-nvim.utils.pretty-ts-errors')
            return ts_errors.format(diagnostic, {
              href = false,
            })
          end,
        },

        render = {
          expand_separators = false,
          -- render-markdown conceals the closing fence (code.border = 'hide')
          -- after eagle has already sized the float, leaving a blank row behind
          concealed_fence_rows = 1,
          severity = {
            ERROR = { icon = Conf.icons.diagnostics.ERROR, hl = 'RenderMarkdownError' },
            WARN = { icon = Conf.icons.diagnostics.WARN, hl = 'RenderMarkdownWarn' },
            INFO = { icon = Conf.icons.diagnostics.INFO, hl = 'RenderMarkdownInfo' },
            HINT = { icon = Conf.icons.diagnostics.HINT, hl = 'RenderMarkdownHint' },
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
            eagle.ignore_next_cursor_move()
            common.focus_win(current_win)
          end, 'Focus Parent Window')

          current_map({ 'n', 'x' }, '<Esc>', close_eagle, 'Close Eagle')
          current_map({ 'n', 'x' }, '<Tab>', function()
            eagle.ignore_next_cursor_move()
            common.focus_win(eagle_win)
          end, 'Focus Eagle Window')
        end,
      }
    end,
  },
}
