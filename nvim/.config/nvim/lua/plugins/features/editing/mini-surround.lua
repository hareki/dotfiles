local mappings = {
  add = 'sa',
  delete = 'sd',
  replace = 'sr',
}

return {
  'echasnovski/mini.surround',
  keys = function()
    return {
      { mappings.add, mode = { 'x' }, desc = 'Mini Surround: Add' },
      { mappings.delete, mode = { 'n', 'x' }, desc = 'Mini Surround: Delete' },
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
}
