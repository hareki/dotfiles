---@class utils.buffer
local M = {}

M.lualine = function()
  local ignore_filetypes = {
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

  if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
    return ''
  end

  local bufnr = 0
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

  return table.concat(out)
end

return M
