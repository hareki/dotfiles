vim.filetype.add({
  extension = {
    mdx = 'mdx',
    ghostty = 'ghostty',
  },
  pattern = {
    ['.*ghostty/config.*'] = 'ghostty',
    ['.*ghostty/themes/.*'] = 'ghostty',

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
