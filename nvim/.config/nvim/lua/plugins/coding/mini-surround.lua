local mappings = {
  add = 'sa', -- Add surrounding
  delete = 'sd', -- Delete surrounding
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
        -- Revert default behavior, I want left brackets to leave no whitespace while right brackets do
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
