vim.filetype.add({
  extension = {
    mdx = 'mdx',
    ghostty = 'ghostty',
  },
  pattern = {
    ['.*ghostty/config.*'] = 'ghostty',
    ['.*ghostty/themes/.*'] = 'ghostty',

    -- Angular templates sit next to a same-named .ts (app.html + app.ts) in an Angular workspace;
    -- the cheap sibling check runs before the upward workspace walk, so static html stays 'html'
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
