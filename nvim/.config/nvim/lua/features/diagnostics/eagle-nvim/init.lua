--- @module 'eagle'
local eagle = Defer.on_exported_call('eagle')

--- @module 'utils.common'
local common = Defer.on_exported_call('utils.common')

return {
  'hareki/eagle.nvim',
  cmd = { 'EagleWin', 'EagleWinLineDiagnostic' },
  opts = function()
    return {
      order = 3, -- LSP info comes first
      show_headers = false,
      keyboard = { enabled = true },
      mouse = { enabled = false },

      window = {
        border = 'rounded',
        max_height = UI.layout.inline_max_height,
        max_width = UI.layout.inline_max_width,
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
        local function eagle_map(lhs, rhs, desc)
          vim.keymap.set({ 'n', 'x' }, lhs, rhs, { buffer = eagle_buf, desc = desc })
        end

        eagle_map('<PageUp>', '<C-u>', 'Scroll Up')
        eagle_map('<PageDown>', '<C-d>', 'Scroll Down')

        common.link_popup(eagle_win, {
          name = 'Eagle',
          modes = { 'n', 'x' },
          before_focus = eagle.ignore_next_cursor_move,
        })
      end,
    }
  end,
}
