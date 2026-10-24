return {
  opts = {
    filetypes = { 'html', 'handlebars' },
    settings = {
      html = {
        format = {
          -- Handlebars formatting (prettier can't, see conform-nvim.lua): keep mustaches atomic and
          -- indent their blocks, or the formatter splits `{{#if` across lines
          templating = true,
          indentHandlebars = true,
          -- Skips the embedded JS/CSS sub-formatters, which silently corrupt mustaches inside
          -- <script>/<style> (`{{{json x}}}` => `{{{json x} }}`)
          unformatted = 'script,style',
          wrapLineLength = 100,
        },
      },
    },
  },
}
