---@class plugins.chrome.dropbar.utils
local M = {}

local IGNORED_FILETYPES = { help = true, trouble = true, ['grug-far'] = true }
local IGNORED_BUFTYPES = { terminal = true }

---Check if current window is in diff view
---@return boolean
function M.is_in_diff_view()
  if vim.wo.diff then
    return true
  end
  -- Check if buffer path is inside a subdirectory of .git/ (e.g. diffview temporary files).
  -- Direct children like COMMIT_EDITMSG must not match.
  local name = vim.api.nvim_buf_get_name(0)
  local git_pos = name:find('/.git/', 1, true)
  if git_pos then
    local after = name:sub(git_pos + 6) -- skip past '/.git/'
    return after:find('/', 1, true) ~= nil
  end
  return false
end

---Check if current window is in claude diff view
---@return boolean
function M.is_in_claude_diff_view()
  return vim.b.claudecode_diff_new_win ~= nil
end

---Check if buffer has an ignored filetype
---@param buf integer Buffer number
---@return boolean
function M.is_ignored_filetype(buf)
  return IGNORED_FILETYPES[vim.bo[buf].filetype] == true
end

---Check if buffer has an ignored buftype
---@param buf integer Buffer number
---@return boolean
function M.is_ignored_buftype(buf)
  return IGNORED_BUFTYPES[vim.bo[buf].buftype] == true
end

---Determine if dropbar should be enabled for a buffer/window
---Filters out help files, terminals, and large files (>1MB).
---@param buf integer Buffer number
---@param win integer Window handle
---@param _ table|nil Additional info (unused)
---@return boolean enabled True if dropbar should be enabled
function M.enable(buf, win, _)
  buf = (buf == 0 or buf == nil) and vim.api.nvim_get_current_buf() or buf
  if
    not vim.api.nvim_buf_is_valid(buf)
    or not vim.api.nvim_win_is_valid(win)
    or vim.fn.win_gettype(win) ~= ''
    or vim.wo[win].winbar ~= ''
    or M.is_ignored_filetype(buf)
    or M.is_ignored_buftype(buf)
  then
    return false
  end

  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
  if stat and stat.size > 1024 * 1024 then
    return false
  end

  return true
end

-- From https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/dropbar.lua
-- I just don't like the default colors for kinds, so declare them all myself
M.KIND_SUFFIXES = {
  'Array',
  'Boolean',
  'BreakStatement',
  'Call',
  'CaseStatement',
  'Class',
  'Constant',
  'Constructor',
  'ContinueStatement',
  'Declaration',
  'Delete',
  'DoStatement',
  'ElseStatement',
  'Enum',
  'EnumMember',
  'Event',
  'Field',
  'File',
  'Folder',
  'ForStatement',
  'Function',
  'Identifier',
  'IfStatement',
  'Interface',
  'Keyword',
  'List',
  'Macro',
  'MarkdownH1',
  'MarkdownH2',
  'MarkdownH3',
  'MarkdownH4',
  'MarkdownH5',
  'MarkdownH6',
  'Method',
  'Module',
  'Namespace',
  'Null',
  'Number',
  'Object',
  'Operator',
  'Package',
  'Property',
  'Reference',
  'Repeat',
  'Scope',
  'Specifier',
  'Statement',
  'String',
  'Struct',
  'SwitchStatement',
  'Type',
  'TypeParameter',
  'Unit',
  'Value',
  'Variable',
  'WhileStatement',
}

return M
