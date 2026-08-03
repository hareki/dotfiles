--- @class config.filetypes.groups
local M = {}

function M.merge(...)
  local result = {}
  for i = 1, select('#', ...) do
    vim.list_extend(result, (select(i, ...)))
  end
  return result
end

-- Atomic groups
M.JS = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' }
M.JSX = { 'javascriptreact', 'typescriptreact' }
M.JS_FRAMEWORK = { 'astro' }
M.ANGULAR = { 'htmlangular' }
M.CSS = { 'css', 'scss', 'less' }
M.JSON = { 'json', 'jsonc', 'json5' }
M.MARKUP = { 'html', 'xml' }
M.MARKDOWN = { 'markdown', 'mdx' }

-- Composed groups
M.JS_ALL = M.merge(M.JS, M.JS_FRAMEWORK)
M.WITH_TAGS = M.merge(M.MARKUP, M.JSX, M.JS_FRAMEWORK, M.ANGULAR)

return M
