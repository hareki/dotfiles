local lualine_require = require('lualine_require')
local component = lualine_require.require('lualine.component')
local unmerged_icon = Icons.git.unmerged .. ' '

---@class plugins.chrome.lualine.components.buffer_status : lualine.component
local M = component:extend()

local IGNORE_FILETYPES = {
  NvimTree = true,
  lazy = true,
  mason = true,
  TelescopePrompt = true,
  TelescopeResults = true,
  Trouble = true,
  help = true,
  lspinfo = true,
  checkhealth = true,
  [''] = true,
}
---@class plugins.chrome.lualine.components.buffer_status.Cache
---@field current_unsaved string
---@field global_unsaved string
---@field global_conflict string
---@field last_bufnr number

---@type plugins.chrome.lualine.components.buffer_status.Cache
local cache = {
  current_unsaved = '',
  global_unsaved = '',
  global_conflict = '',
  last_bufnr = -1,
}

local function invalidate_cache()
  cache.current_unsaved = ''
  cache.global_unsaved = ''
  cache.global_conflict = ''
  cache.last_bufnr = -1
end

-- Set up autocmds to invalidate cache on relevant events
local group = vim.api.nvim_create_augroup('LualineBufferStatusCache', { clear = true })
vim.api.nvim_create_autocmd({
  'BufReadPost',
  'BufWritePost',
  'BufModifiedSet',
  'BufEnter',
  'BufDelete',
  'BufWipeout',
}, {
  group = group,
  callback = invalidate_cache,
})
vim.api.nvim_create_autocmd('User', {
  group = group,
  pattern = { 'GitConflictDetected', 'GitConflictResolved' },
  callback = invalidate_cache,
})

---Get current buffer flags (new, readonly, modified)
---@return string
local function get_current_unsaved()
  local bufnr = vim.api.nvim_get_current_buf()

  if cache.last_bufnr == bufnr and cache.current_unsaved ~= '' then
    return cache.current_unsaved
  end

  if IGNORE_FILETYPES[vim.bo.filetype] then
    cache.current_unsaved = ''
    cache.last_bufnr = bufnr
    return ''
  end

  local status = Icons.file_status
  local bo = vim.bo[bufnr]
  local name = vim.api.nvim_buf_get_name(bufnr) or ''

  local out = {}

  if name == '' then
    if status.unnamed ~= '' then
      out[#out + 1] = status.unnamed
    end
  else
    if bo.buftype == '' then
      if not vim.uv.fs_stat(name) and status.new ~= '' then
        out[#out + 1] = status.new
      end
    end
  end

  local is_readonly = (bo.readonly or not bo.modifiable) and status.readonly ~= ''
  if is_readonly then
    out[#out + 1] = status.readonly
  end

  local is_modified = bo.modified and status.modified ~= '' and not is_readonly
  if is_modified then
    out[#out + 1] = status.modified
  end

  local result = table.concat(out)
  cache.current_unsaved = result
  cache.last_bufnr = bufnr

  return result
end

---Get global modified flag (count of other modified buffers)
---@return string
local function get_global_unsaved()
  if cache.global_unsaved ~= '' then
    return cache.global_unsaved
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current_bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      local bo = vim.bo[bufnr]

      if
        vim.api.nvim_buf_get_name(bufnr) ~= ''
        and not bo.readonly
        and bo.buftype == ''
        and bo.modified
        and bo.modifiable
        and not IGNORE_FILETYPES[bo.filetype]
      then
        count = count + 1
      end
    end
  end

  local status = Icons.file_status
  local result = count > 0 and status.modified .. count .. '  ' or ''
  cache.global_unsaved = result

  return result
end

---Get conflict flag for the current buffer
---@return string
local function get_current_conflict()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].git_conflict then
    return unmerged_icon
  end
  return ''
end

---Get global conflict flag (count of other conflicted buffers)
---@return string
local function get_global_conflict()
  if cache.global_conflict ~= '' then
    return cache.global_conflict
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current_bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      if vim.b[bufnr].git_conflict then
        count = count + 1
      end
    end
  end

  local result = count > 0 and unmerged_icon .. count .. ' ' or ''
  cache.global_conflict = result

  return result
end

---Default options for buffer status component
local default_options = {
  colored = true,
  symbols = {
    current_unsaved = '', -- Will use current_unsaved result directly
    global_unsaved = '', -- Will use global_unsaved result directly
    current_conflict = '', -- Will use current_conflict result directly
    global_conflict = '', -- Will use global_conflict result directly
  },
}

---Apply default colors from palette
---@param opts table
local function apply_default_colors(opts)
  local ui = require('utils.ui')
  local palette = ui.get_palette()

  local default_status_color = {
    current_unsaved = { fg = palette.yellow },
    global_unsaved = { fg = palette.red },
    current_conflict = { fg = palette.yellow },
    global_conflict = { fg = palette.red },
  }

  opts.status_color = vim.tbl_deep_extend('keep', opts.status_color or {}, default_status_color)
end

---Initialize the component
---@param options table
function M:init(options)
  M.super.init(self, options)
  apply_default_colors(self.options)
  self.options = vim.tbl_deep_extend('keep', self.options or {}, default_options)

  if self.options.colored then
    self.highlight_groups = {
      current_unsaved = self:create_hl(
        self.options.status_color.current_unsaved,
        'current_unsaved'
      ),
      global_unsaved = self:create_hl(self.options.status_color.global_unsaved, 'global_unsaved'),
      current_conflict = self:create_hl(
        self.options.status_color.current_conflict,
        'current_conflict'
      ),
      global_conflict = self:create_hl(
        self.options.status_color.global_conflict,
        'global_conflict'
      ),
    }
  end
end

---Update and return the status string
---@return string
function M:update_status()
  local current_unsaved = get_current_unsaved()
  local global_unsaved = get_global_unsaved()
  local current_conflict = get_current_conflict()
  local global_conflict = get_global_conflict()

  if
    current_unsaved == ''
    and global_unsaved == ''
    and current_conflict == ''
    and global_conflict == ''
  then
    return ''
  end

  local result = {}

  if self.options.colored then
    local colors = {}
    for name, hl in pairs(self.highlight_groups) do
      colors[name] = self:format_hl(hl)
    end

    if current_unsaved ~= '' then
      table.insert(result, colors.current_unsaved .. current_unsaved)
    end

    if global_unsaved ~= '' then
      table.insert(result, colors.global_unsaved .. global_unsaved)
    end

    if current_conflict ~= '' then
      table.insert(result, colors.current_conflict .. current_conflict)
    end

    if global_conflict ~= '' then
      table.insert(result, colors.global_conflict .. global_conflict)
    end
  else
    if current_unsaved ~= '' then
      table.insert(result, current_unsaved)
    end

    if global_unsaved ~= '' then
      table.insert(result, global_unsaved)
    end

    if current_conflict ~= '' then
      table.insert(result, current_conflict)
    end

    if global_conflict ~= '' then
      table.insert(result, global_conflict)
    end
  end

  return table.concat(result, '')
end

return M
