local util = require('lspconfig.util')

return {
  opts = {
    -- nvim-lspconfig's root_dir minus its closing `.git` fallback, which started an idle server in
    -- every git repo; Tailwind v4 projects still match through a package.json with tailwindcss
    root_dir = function(bufnr, on_dir)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      local markers = util.insert_package_json({
        'tailwind.config.js',
        'tailwind.config.cjs',
        'tailwind.config.mjs',
        'tailwind.config.ts',
        'postcss.config.js',
        'postcss.config.cjs',
        'postcss.config.mjs',
        'postcss.config.ts',
        'theme/static_src/tailwind.config.js',
        'theme/static_src/tailwind.config.cjs',
        'theme/static_src/tailwind.config.mjs',
        'theme/static_src/tailwind.config.ts',
        'theme/static_src/postcss.config.js',
      }, 'tailwindcss', fname)
      markers =
        util.root_markers_with_field(markers, { 'mix.lock', 'Gemfile.lock' }, 'tailwind', fname)
      -- Nested: every marker has equal priority, so the nearest directory with any of them wins
      on_dir(vim.fs.root(fname, { markers }))
    end,

    settings = {
      tailwindCSS = {
        classFunctions = { 'cva', 'tw', 'cn', 'tv', 'cx' },
      },
    },
  },
}
