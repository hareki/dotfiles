return {
  opts = {
    filetypes = { 'html', 'handlebars' },
    settings = {
      html = {
        format = {
          -- Handlebars: keep mustaches atomic, or the formatter splits `{{#if` across lines
          templating = true,
          indentHandlebars = true,
          -- The JS/CSS sub-formatters corrupt mustaches (`{{{json x}}}` => `{{{json x} }}`)
          unformatted = 'script,style',
          wrapLineLength = 100,
        },
      },
    },
  },
}
