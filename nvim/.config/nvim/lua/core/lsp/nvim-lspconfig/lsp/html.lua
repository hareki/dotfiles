return {
  opts = {
    filetypes = { 'html', 'handlebars' },
    settings = {
      html = {
        format = {
          -- Handlebars formatting (prettier can't do it, see conform-nvim.lua):
          -- treat mustaches as atomic tokens and indent their blocks, otherwise
          -- the formatter splits `{{#if` across lines
          templating = true,
          indentHandlebars = true,
          -- Gates off the embedded JS/CSS sub-formatters, which are handlebars-
          -- unaware and silently corrupt mustaches inside <script>/<style>
          -- (`{{{json x}}}` => `{{{json x} }}`, `:root {` + `{{#each}}` merged
          -- into `:root {{{#each}}` and reparsed as literal text)
          unformatted = 'script,style',
          wrapLineLength = 100,
        },
      },
    },
  },
}
