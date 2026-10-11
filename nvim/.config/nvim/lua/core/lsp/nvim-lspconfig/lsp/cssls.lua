-- Don't throw warnings for tailwind at rules
local lint = { lint = { unknownAtRules = 'ignore' } }

return {
  opts = {
    settings = {
      css = lint,
      scss = lint,
      less = lint,
    },
  },
}
