local prefix = 'gs'
local mappings = {
  add = prefix .. 'a',
  delete = prefix .. 'd',
  replace = prefix .. 'r',
}

return {
  UI.which_key({
    specs = { prefix, group = 'Mini Surround' },
    rules = { pattern = 'mini.surround', icon = Conf.icons.tools.SURROUND, color = 'green' },
  }),

  {
    'echasnovski/mini.surround',
    keys = function()
      return {
        { mappings.add, mode = { 'n', 'x' }, desc = 'Mini Surround: Add' },
        { mappings.delete, mode = { 'n' }, desc = 'Mini Surround: Delete' },
        { mappings.replace, mode = { 'n' }, desc = 'Mini Surround: Replace' },
      }
    end,
    opts = function()
      return {
        mappings = mappings,
        custom_surroundings = {
          -- Revert default: left brackets leave no whitespace, right brackets add whitespace
          [')'] = { input = { '%b()', '^.%s*().-()%s*.$' }, output = { left = '( ', right = ' )' } },
          ['('] = { input = { '%b()', '^.().*().$' }, output = { left = '(', right = ')' } },
          [']'] = { input = { '%b[]', '^.%s*().-()%s*.$' }, output = { left = '[ ', right = ' ]' } },
          ['['] = { input = { '%b[]', '^.().*().$' }, output = { left = '[', right = ']' } },
          ['}'] = { input = { '%b{}', '^.%s*().-()%s*.$' }, output = { left = '{ ', right = ' }' } },
          ['{'] = { input = { '%b{}', '^.().*().$' }, output = { left = '{', right = '}' } },
          ['>'] = { input = { '%b<>', '^.%s*().-()%s*.$' }, output = { left = '< ', right = ' >' } },
          ['<'] = { input = { '%b<>', '^.().*().$' }, output = { left = '<', right = '>' } },
        },
      }
    end,
  },
}
