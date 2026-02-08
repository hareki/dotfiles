local lualine_require = require('lualine_require')
local component = lualine_require.require('lualine.component')

---@class plugins.ui.lualine.components.buffer_status
local M = component:extend()

local IGNORE_FILETYPES = {
  'NvimTree',
  'lazy',
  'mason',
  'TelescopePrompt',
  'TelescopeResults',
  'toggleterm',
  'Trouble',
  'help',
  'lspinfo',
  'checkhealth',
  '',
}
---@class plugins.ui.lualine.components.buffer_status.Cache
---@field current_flags string
---@field global_modified string
---@field last_bufnr number

---@type plugins.ui.lualine.components.buffer_status.Cache
local cache = {
  current_flags = '',
  global_modified = '',
  last_bufnr = -1,
}

local function invalidate_cache()
  cache.current_flags = ''
  cache.global_modified = ''
  cache.last_bufnr = -1
end

-- Set up autocmds to invalidate cache on relevant events
local group = vim.api.nvim_create_augroup('LualineBufferStatusCache', { clear = true })
vim.api.nvim_create_autocmd({
  'TextChanged',
  'TextChangedI',
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

---Get current buffer flags (new, readonly, modified)
---@return string
local function get_current_flags()
  local bufnr = vim.api.nvim_get_current_buf()

  if cache.last_bufnr == bufnr and cache.current_flags ~= '' then
    return cache.current_flags
  end

  if vim.list_contains(IGNORE_FILETYPES, vim.bo.filetype) then
    cache.current_flags = ''
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
  cache.current_flags = result
  cache.last_bufnr = bufnr

  return result
end

---Get global modified flag (count of other modified buffers)
---@return string
local function get_global_modified()
  if cache.global_modified ~= '' then
    return cache.global_modified
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
        and not vim.list_contains(IGNORE_FILETYPES, bo.filetype)
      then
        count = count + 1
      end
    end
  end

  local status = Icons.file_status
  local result = count > 0 and status.modified .. count or ''
  cache.global_modified = result

  return result
end

---Default options for buffer status component
local default_options = {
  colored = true,
  symbols = {
    current = '', -- Will use current_flags result directly
    global = '', -- Will use global_modified result directly
  },
}

---Apply default colors from palette
---@param opts table
local function apply_default_colors(opts)
  local ui = require('utils.ui')
  local palette = ui.get_palette()

  local default_status_color = {
    current = { fg = palette.yellow },
    global = { fg = palette.red },
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
      current = self:create_hl(self.options.status_color.current, 'current'),
      global = self:create_hl(self.options.status_color.global, 'global'),
    }
  end
end

---Update and return the status string
---@return string
function M:update_status()
  local current_flags = get_current_flags()
  local global_modified = get_global_modified()

  if current_flags == '' and global_modified == '' then
    return ''
  end

  local result = {}

  if self.options.colored then
    local colors = {}
    for name, hl in pairs(self.highlight_groups) do
      colors[name] = self:format_hl(hl)
    end

    if current_flags ~= '' then
      table.insert(result, colors.current .. current_flags)
    end

    if global_modified ~= '' then
      table.insert(result, colors.global .. global_modified)
    end
  else
    if current_flags ~= '' then
      table.insert(result, current_flags)
    end

    if global_modified ~= '' then
      table.insert(result, global_modified)
    end
  end

  return table.concat(result, '')
end

return M
