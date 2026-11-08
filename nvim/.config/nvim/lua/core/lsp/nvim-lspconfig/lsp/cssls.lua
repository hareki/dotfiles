-- Don't throw warnings for tailwind at rules
local LINT = { lint = { unknownAtRules = 'ignore' } }

return {
  opts = {
    settings = {
      css = LINT,
      scss = LINT,
      less = LINT,
    },
  },
}
