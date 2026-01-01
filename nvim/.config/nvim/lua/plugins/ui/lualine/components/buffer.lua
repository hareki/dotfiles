---@class plugins.ui.lualine.components.buffer
local M = {}

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

local cache = {
  current_buffer_flags = '',
  global_modified_flag = '',
  last_bufnr = -1,
}

local function invalidate_cache()
  cache.current_buffer_flags = ''
  cache.global_modified_flag = ''
  cache.last_bufnr = -1
end

-- Set up autocmds to invalidate cache on relevant events
local group = vim.api.nvim_create_augroup('LualineBufferCache', { clear = true })
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

function M.current_buffer_flags()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Return cached result if buffer hasn't changed
  if cache.last_bufnr == bufnr and cache.current_buffer_flags ~= '' then
    return cache.current_buffer_flags
  end

  if vim.list_contains(IGNORE_FILETYPES, vim.bo.filetype) then
    cache.current_buffer_flags = ''
    cache.last_bufnr = bufnr
    return ''
  end

  local status = require('configs.icons').file_status
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

  -- No point of showing modified flag if we can't write to it
  local is_modified = bo.modified and status.modified ~= '' and not is_readonly
  if is_modified then
    out[#out + 1] = status.modified
  end

  local result = table.concat(out)
  cache.current_buffer_flags = result
  cache.last_bufnr = bufnr
  return result
end

function M.global_modified_flag()
  -- Return cached result if available
  if cache.global_modified_flag ~= '' then
    return cache.global_modified_flag
  end

  local current_bufnr = vim.api.nvim_get_current_buf()
  local count = 0

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current_bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      local bo = vim.bo[bufnr]

      -- Check if it's a true file buffer that's modified
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

  local status = require('configs.icons').file_status
  local result = count > 0 and status.modified .. count or ''
  cache.global_modified_flag = result
  return result
end

return M
