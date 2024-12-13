---@class util.common
local M = {}

M.aucmd = vim.api.nvim_create_autocmd
M.clear_aucmd = vim.api.nvim_clear_autocmds

M.map = vim.keymap.set
M.unmap = vim.keymap.del

M.cwd = vim.fn.getcwd

--- @param name string
M.lazy_augroup = function(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
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

--- @param name? "frappe" | "latte" | "macchiato" | "mocha"
M.get_palette = function(name)
  return require("catppuccin.palettes").get_palette(name or "mocha")
end

M.get_initial_path = function()
  -- Get the first argument passed to Neovim (which is usually the path)
  local first_arg = vim.fn.argv(0)

  -- If the path is relative, resolve it to an absolute path
  local initial_path = vim.fn.fnamemodify(tostring(first_arg), ":p")

  return initial_path
end

M.remove_lualine_component = function(name, tbl)
  -- Iterate through the table in reverse to avoid issues when removing elements (skipping elements)
  for i = #tbl, 1, -1 do
    if tbl[i][1] == name then
      table.remove(tbl, i)
    end
  end
end

--- Ensures a nested path exists in the given table.
--- @param t table The table to operate on.
--- @param key_string string The dot-separated string representing the nested keys.
--- @return table nested_table the innermost table that was ensured.
function M.define(t, key_string)
  local keys = {}
  for key in key_string:gmatch("[^%.]+") do
    table.insert(keys, key)
  end

  for _, key in ipairs(keys) do
    if t[key] == nil then
      t[key] = {}
    end
    t = t[key]
  end
  return t
end

function M.get_rendered_tabline()
  local tabs = vim.api.nvim_list_tabpages()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local tabline = ""

  local fixed_width = 15

  for index, tab in ipairs(tabs) do
    local is_current = (tab == current_tab)

    if is_current then
      tabline = tabline .. "%#TabLineSel#"
    else
      tabline = tabline .. "%#TabLine#"
    end

    -- Start clickable area
    tabline = tabline .. "%" .. index .. "T"

    -- Prepare the tab number centered within fixed_width
    local tab_number = "Tab " .. tostring(index)
    if is_current then
      tab_number = "[" .. tab_number .. "]"
    end
    local padding_total = fixed_width - #tab_number
    if padding_total < 0 then
      padding_total = 0 -- Prevent negative padding
    end
    local padding_left = math.floor(padding_total / 2)
    local padding_right = padding_total - padding_left
    local tab_label = string.rep(" ", padding_left) .. tab_number .. string.rep(" ", padding_right)

    -- Add the tab label
    tabline = tabline .. tab_label

    -- Explicitly reset the clickable area
    tabline = tabline .. "%T"

    if index < #tabs then
      tabline = tabline .. "%#TabLine#|"
    end
  end

  -- Fill the rest of the tabline area
  tabline = tabline .. "%#TabLineFill#"

  return tabline
end

--- Get the file path relative to the given root.
--- @return string
function M.get_relative_path(file, root)
  -- Ensure both paths are absolute
  local absolute_file = vim.fn.fnamemodify(file, ":p")
  local absolute_root = vim.fn.fnamemodify(root, ":p")

  -- Normalize paths by removing trailing slashes
  if absolute_root:sub(-1) == "/" then
    absolute_root = absolute_root:sub(1, -2)
  end
  if absolute_file:sub(-1) == "/" then
    absolute_file = absolute_file:sub(1, -2)
  end

  -- Check if the file path starts with the root path
  if absolute_file:sub(1, #absolute_root) == absolute_root then
    -- Extract the relative path by removing the root path and the following slash
    local relative = absolute_file:sub(#absolute_root + 2)
    return relative
  else
    -- If the file is not inside the root, return the absolute path
    return absolute_file
  end
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
  local path = opts.path or vim.fn.expand("%:p:h")
  for dir in string.gmatch(path, "[^/]+") do
    if dir == dir_name then
      return true
    end
  end
  return false
end

return M
