return {
  opts = {
    -- Don't throw warnings for tailwind at rules
    settings = {
      css = {
        validate = true,
        lint = { unknownAtRules = 'ignore' },
      },
      scss = {
        validate = true,
        lint = { unknownAtRules = 'ignore' },
      },
      less = {
        validate = true,
        lint = { unknownAtRules = 'ignore' },
      },
    },
  },
}
