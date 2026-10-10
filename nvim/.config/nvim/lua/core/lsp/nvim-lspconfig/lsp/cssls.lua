return {
  opts = {
    -- Don't throw warnings for tailwind at rules
    settings = {
      css = {
        lint = { unknownAtRules = 'ignore' },
      },
      scss = {
        lint = { unknownAtRules = 'ignore' },
      },
      less = {
        lint = { unknownAtRules = 'ignore' },
      },
    },
  },
}
