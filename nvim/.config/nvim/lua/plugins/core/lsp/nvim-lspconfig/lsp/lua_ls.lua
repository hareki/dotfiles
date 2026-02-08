return {
  opts = {
    settings = {
      Lua = {
        diagnostics = {
          unusedLocalExclude = { '_*' }, -- ignore _foo, _bar, _
        },
      },
    },
  },
}
