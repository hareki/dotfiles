-- TODO: Lazy load/split functions and add documents
---@class util.common
local M = {}

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
M.get_palette = function(name)
  return require('catppuccin.palettes').get_palette(name or 'mocha')
end

---@generic T
---@param list T[]
---@return T[]
function M.deduplicate_list(list)
  local result = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(result, v)
      seen[v] = true
    end
  end
  return result
end

--- @param group string
--- @param style vim.api.keyset.highlight
M.highlight = function(group, style)
  vim.api.nvim_set_hl(0, group, style)
end

--- A table of custom highlight groups and their corresponding styles.
--- @param custom_highlights table<string, vim.api.keyset.highlight>
M.highlights = function(custom_highlights)
  for group, style in pairs(custom_highlights) do
    Util.highlight(group, style)
  end
end

function M.is_loaded(name)
  local Config = require('lazy.core.config')
  return Config.plugins[name] and Config.plugins[name]._.loaded
end

-- LazyVim
---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  if M.is_loaded(name) then
    fn(name)
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'LazyLoad',
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

M.get_initial_path = function()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(tostring(first_arg), ':p')

  return initial_path
end

--- @class util.common.HasDirOptions
--- @field dir_name string     The directory name to search for (required).
--- @field path? string        The file system path to search (optional).
---
--- Checks whether a directory with the specified name exists in the given path components.
--- @param opts util.common.HasDirOptions  A table containing the options.
--- @return boolean            `true` if the directory is found in the path components, otherwise `false`.
function M.has_dir(opts)
  local dir_name = opts.dir_name
  local path = opts.path or vim.fn.expand('%:p:h')
  for dir in string.gmatch(path, '[^/]+') do
    if dir == dir_name then
      return true
    end
  end
  return false
end

function M.custom_lazy_events()
  -- LazyFile
  local Event = require('lazy.core.handler.event')
  Event.mappings.LazyFile =
    { id = 'LazyFile', event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' } }
  Event.mappings['User LazyFile'] = Event.mappings.LazyFile
end

return M
