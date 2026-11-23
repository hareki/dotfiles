local filetypes = Conf.filetypes

-- The filetypes oxfmt owns. Upstream adds toml (taplo's), astro, which fails unless enabled, and
-- graphql, vue, svelte and handlebars, where conform's LSP fallback would follow html.lua's server
return {
  opts = {
    filetypes = filetypes.merge(
      filetypes.JS, -- No astro
      filetypes.CSS,
      filetypes.JSON,
      { 'html', 'markdown', 'yaml' } -- No mdx
    ),
  },
}
