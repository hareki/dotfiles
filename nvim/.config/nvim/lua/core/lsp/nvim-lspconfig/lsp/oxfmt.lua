local filetypes = Conf.filetypes

-- The filetypes oxfmt owns; upstream also attaches it to toml (taplo's), graphql, vue, svelte and
-- handlebars, where conform's LSP fallback would format after the html server (see html.lua)
return {
  opts = {
    -- Upstream's root_dir answers nil outside an oxfmt project, which starts a rootless server
    workspace_required = true,

    filetypes = filetypes.merge(
      filetypes.JS, -- No astro
      filetypes.CSS,
      filetypes.JSON,
      { 'html', 'markdown', 'yaml' } -- No mdx
    ),
  },
}
