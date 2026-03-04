---@class config.filetypes
local M = {}

function M.merge(...)
  local result = {}
  for i = 1, select('#', ...) do
    vim.list_extend(result, (select(i, ...)))
  end
  return result
end

-- Atomic groups
M.js = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' }
M.jsx = { 'javascriptreact', 'typescriptreact' }
M.js_framework = { 'astro' }
M.css = { 'css', 'scss', 'less' }
M.json = { 'json', 'jsonc', 'json5' }
M.markup = { 'html', 'xml' }
M.markdown = { 'markdown', 'mdx' }

-- Composed groups
M.js_all = M.merge(M.js, M.js_framework)
M.with_tags = M.merge(M.markup, M.jsx, M.js_framework)

return M
