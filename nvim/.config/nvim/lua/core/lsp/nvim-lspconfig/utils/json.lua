--- @class core.lsp.nvim-lspconfig.utils.json
local M = {}

--- @param path string
--- @return table? json nil when the file is missing or doesn't hold a JSON object or array
function M.read(path)
  local file = io.open(path)
  if not file then
    return nil
  end

  local ok, json = pcall(vim.json.decode, file:read('*a'))
  file:close()

  return ok and type(json) == 'table' and json or nil
end

return M
