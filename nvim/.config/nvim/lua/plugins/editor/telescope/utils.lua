local M = {}
-- remove bufnr + flags from Telescope buffers display
function M.shorten_entry_maker(opts)
  local entry_display = require('telescope.pickers.entry_display')
  local make_entry = require('telescope.make_entry')
  local utils = require('telescope.utils')
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

  opts = opts or {}
  local inner = make_entry.gen_from_buffer(opts)
  local displayer = entry_display.create({
    separator = '',
    items = {
      has_devicons and { width = 2 } or nil,
      { remaining = true },
    },
  })

  return function(item)
    local e = inner(item)
    local path = vim.api.nvim_buf_get_name(e.bufnr)
    local display_path = utils.transform_path(opts, path)

    e.display = function()
      if has_devicons then
        local tail = utils.path_tail(path)
        local icon, hl = devicons.get_icon(tail, nil, { default = true })
        return displayer({ { icon, hl }, display_path })
      end
      return display_path
    end

    return e
  end
end

return M
