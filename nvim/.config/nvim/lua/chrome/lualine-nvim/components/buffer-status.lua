local component = require('lualine.component')
local unmerged_icon = Conf.icons.git.UNMERGED .. ' '

--- @class chrome.lualine.components.buffer-status : lualine.component
local M = component:extend()

-- getbufvar rather than vim.bo for other buffers: vim.bo reads a hidden buffer's option by
-- switching into the autocmd window (~10us per read, against ~0.2us). Booleans come back as 0/1
local getbufvar = vim.fn.getbufvar

local IGNORE_FILETYPES = {
  NvimTree = true,
  lazy = true,
  trouble = true,
  help = true,
  checkhealth = true,
}
--- @class chrome.lualine.components.buffer-status.Cache
--- @field current_unsaved string | nil
--- @field global_unsaved string | nil
--- @field global_conflict string | nil
--- @field last_bufnr number

--- @type chrome.lualine.components.buffer-status.Cache
local cache = {
  current_unsaved = nil,
  global_unsaved = nil,
  global_conflict = nil,
  last_bufnr = -1,
}

local function invalidate_cache()
  cache.current_unsaved = nil
  cache.global_unsaved = nil
  cache.global_conflict = nil
  cache.last_bufnr = -1
end

local group = vim.api.nvim_create_augroup('chrome.lualine.buffer-status-cache', { clear = true })
vim.api.nvim_create_autocmd({
  'BufReadPost',
  'BufWritePost',
  'BufModifiedSet',
  'BufEnter',
  'BufDelete',
  'BufWipeout',
  -- Renames (:file, nvim_buf_set_name, Snacks.rename) fire only BufFilePre/Post
  'BufFilePost',
}, {
  group = group,
  callback = invalidate_cache,
})
vim.api.nvim_create_autocmd('User', {
  group = group,
  pattern = { 'GitConflictDetected', 'GitConflictResolved' },
  callback = invalidate_cache,
})
-- The readonly icon reads 'readonly'/'modifiable', which :set changes without a buffer event
vim.api.nvim_create_autocmd('OptionSet', {
  group = group,
  pattern = { 'readonly', 'modifiable' },
  callback = invalidate_cache,
})

--- Get current buffer flags (new, readonly, modified)
--- @return string
local function get_current_unsaved()
  local bufnr = vim.api.nvim_get_current_buf()

  if cache.last_bufnr == bufnr and cache.current_unsaved ~= nil then
    return cache.current_unsaved
  end

  local status = Conf.icons.file_status
  local bo = vim.bo[bufnr]
  local ft = bo.filetype
  local name = vim.api.nvim_buf_get_name(bufnr)

  -- Terminals are always nomodifiable (a misleading padlock); empty-filetype nofile/prompt buffers
  -- are UI, while codediff:// views clear their filetype yet still earn the lock icon
  local is_ignored
  if bo.buftype == 'terminal' then
    is_ignored = true
  elseif ft == '' then
    is_ignored = bo.buftype == 'nofile' or bo.buftype == 'prompt'
  else
    is_ignored = IGNORE_FILETYPES[ft]
  end

  if is_ignored then
    cache.current_unsaved = ''
    cache.last_bufnr = bufnr
    return ''
  end

  local out = {}

  if name == '' then
    out[#out + 1] = status.UNNAMED
  elseif bo.buftype == '' and not vim.uv.fs_stat(name) then
    out[#out + 1] = status.NEW
  end

  local is_readonly = bo.readonly or not bo.modifiable or bo.buftype == 'nowrite'
  if is_readonly then
    out[#out + 1] = status.READONLY
  end

  if bo.modified and not is_readonly then
    out[#out + 1] = status.MODIFIED
  end

  local result = table.concat(out)
  cache.current_unsaved = result
  cache.last_bufnr = bufnr

  return result
end

--- @param predicate fun(bufnr: integer): boolean
--- @return integer
local function count_other_loaded(predicate)
  local current_bufnr = vim.api.nvim_get_current_buf()
  local count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current_bufnr and vim.api.nvim_buf_is_loaded(bufnr) and predicate(bufnr) then
      count = count + 1
    end
  end

  return count
end

--- Whether a buffer holds unsaved changes to a writable file
--- @param bufnr integer
--- @return boolean
local function is_unsaved(bufnr)
  return getbufvar(bufnr, '&modified') == 1
    and getbufvar(bufnr, '&buftype') == ''
    and getbufvar(bufnr, '&readonly') == 0
    and getbufvar(bufnr, '&modifiable') == 1
    and vim.api.nvim_buf_get_name(bufnr) ~= ''
end

--- Get global modified flag (count of other modified buffers)
--- @return string
local function get_global_unsaved()
  if cache.global_unsaved == nil then
    local count = count_other_loaded(is_unsaved)
    cache.global_unsaved = count > 0 and Conf.icons.file_status.MODIFIED .. count .. '  ' or ''
  end

  return cache.global_unsaved
end

--- @return string
local function get_current_conflict()
  return vim.b.git_conflict and unmerged_icon or ''
end

--- Get global conflict flag (count of other conflicted buffers)
--- @return string
local function get_global_conflict()
  if cache.global_conflict == nil then
    local count = count_other_loaded(function(bufnr)
      return vim.b[bufnr].git_conflict == true
    end)
    cache.global_conflict = count > 0 and unmerged_icon .. count .. ' ' or ''
  end

  return cache.global_conflict
end

--- Status parts in display order: highlight-group key, getter and palette color
local PARTS = {
  { 'current_unsaved', get_current_unsaved, 'yellow' },
  { 'global_unsaved', get_global_unsaved, 'red' },
  { 'current_conflict', get_current_conflict, 'yellow' },
  { 'global_conflict', get_global_conflict, 'red' },
}

--- @param options table
function M:init(options)
  M.super.init(self, options)

  local palette = UI.catppuccin.get_palette()
  self.highlight_groups = {}
  for _, part in ipairs(PARTS) do
    self.highlight_groups[part[1]] = self:create_hl({ fg = palette[part[3]] }, part[1])
  end
end

--- @return string
function M:update_status()
  local result = {}

  for _, part in ipairs(PARTS) do
    local text = part[2]()
    if text ~= '' then
      -- format_hl calls nvim_get_mode per group, so only pay it for parts that are shown
      result[#result + 1] = self:format_hl(self.highlight_groups[part[1]]) .. text
    end
  end

  return table.concat(result)
end

return M
