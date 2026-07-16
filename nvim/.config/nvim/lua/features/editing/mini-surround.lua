local prefix = 'gs'
local mappings = {
  add = prefix .. 'a',
  delete = prefix .. 'd',
  replace = prefix .. 'r',
  find = prefix .. 'f',
  find_left = prefix .. 'F',
  highlight = prefix .. 'h',

  -- Unused
  suffix_last = '',
  suffix_next = '',
}

return {
  UI.which_key({
    specs = { prefix, group = 'Mini Surround' },
    rules = { pattern = 'mini.surround', icon = Conf.icons.tools.SURROUND, color = 'green' },
  }),

  {
    'echasnovski/mini.surround',
    keys = {
      { mappings.add, mode = { 'n', 'x' }, desc = 'Mini Surround: Add' },
      { mappings.delete, mode = { 'n' }, desc = 'Mini Surround: Delete' },
      { mappings.replace, mode = { 'n' }, desc = 'Mini Surround: Replace' },
      { mappings.find, mode = { 'n', 'x' }, desc = 'Mini Surround: Find' },
      { mappings.find_left, mode = { 'n', 'x' }, desc = 'Mini Surround: Find Left' },
      { mappings.highlight, mode = { 'n', 'x' }, desc = 'Mini Surround: Highlight' },
    },
    opts = function()
      return {
        n_lines = 100,
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
