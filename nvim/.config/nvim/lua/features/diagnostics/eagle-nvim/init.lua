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
          return ts_errors.format(diagnostic)
        end,
      },

      render = {
        expand_separators = false,
        -- render-markdown hides the closing fence after eagle sizes the float, leaving a blank row
        concealed_fence_rows = 1,
        severity = {
          ERROR = { icon = Conf.icons.diagnostics.ERROR, hl = 'RenderMarkdownError' },
          WARN = { icon = Conf.icons.diagnostics.WARN, hl = 'RenderMarkdownWarn' },
          INFO = { icon = Conf.icons.diagnostics.INFO, hl = 'RenderMarkdownInfo' },
          HINT = { icon = Conf.icons.diagnostics.HINT, hl = 'RenderMarkdownHint' },
        },
      },

      on_open = function(eagle_win, eagle_buf)
        local map = common.buf_mapper(eagle_buf)
        map({ 'n', 'x' }, '<PageUp>', '<C-u>', 'Scroll Up')
        map({ 'n', 'x' }, '<PageDown>', '<C-d>', 'Scroll Down')

        common.link_popup(eagle_win, {
          name = 'Eagle',
          modes = { 'n', 'x' },
          before_focus = eagle.ignore_next_cursor_move,
        })
      end,
    }
  end,
}
