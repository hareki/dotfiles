--- @class config.filetypes
local M = {}

vim.filetype.add({
  extension = {
    mdx = 'mdx',
  },
  pattern = {
    -- Angular component templates co-locate a same-named .ts sibling within an
    -- Angular workspace: app.html + app.ts, foo.component.html + foo.component.ts.
    -- The cheap sibling check short-circuits before the upward workspace walk, so
    -- static html (index.html, non-Angular projects) stays plain 'html'.
    ['.*%.html'] = function(path)
      if
        vim.uv.fs_stat((path:gsub('%.html$', '.ts')))
        and vim.fs.root(path, { 'angular.json', 'nx.json' })
      then
        return 'htmlangular'
      end
    end,
  },
})

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
