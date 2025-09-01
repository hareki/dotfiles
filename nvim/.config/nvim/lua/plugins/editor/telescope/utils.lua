local M = {}

function M.shorten_entry_maker(opts)
  local entry_display = require('telescope.pickers.entry_display')
  local make_entry = require('telescope.make_entry')
  local utils = require('telescope.utils')
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  local status = require('configs.icons').file_status

  opts = opts or {}
  local inner = make_entry.gen_from_buffer(opts)

  -- cols: [icon?] [path] [spacer] [marker]
  local displayer = entry_display.create({
    separator = '',
    items = {
      has_devicons and { width = 2 } or nil,
      { remaining = true },
      {}, -- spacer (plain string)
      {}, -- marker (highlighted only if modified)
    },
  })

  return function(item)
    local entry = inner(item)
    local path = vim.api.nvim_buf_get_name(entry.bufnr)
    local display_path = utils.transform_path(opts, path)
    local is_modified = vim.api.nvim_buf_get_option(entry.bufnr, 'modified')

    entry.display = function()
      local spacer = is_modified and ' ' or '' -- unhighlighted space only when needed
      local marker = is_modified and { status.modified, 'TelescopeBufferMarker' } or ''

      if has_devicons then
        local tail = utils.path_tail(path)
        local icon, hl = devicons.get_icon(tail, nil, { default = true })
        return displayer({
          { icon, hl },
          display_path,
          spacer,
          marker,
        })
      end

      return displayer({
        display_path,
        spacer,
        marker,
      })
    end

    return entry
  end
end

return M
