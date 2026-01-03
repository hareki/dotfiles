local mappings = {
  add = 'sa', -- Add surrounding
  delete = 'sd', -- Delete surrounding
  replace = 'sr',
}

return {
  'echasnovski/mini.surround',
  keys = function()
    return {
      { mappings.add, desc = 'Mini Surround: Add', mode = { 'x' } },
      { mappings.delete, desc = 'Mini Surround: Delete', mode = { 'n', 'x' } },
      { mappings.replace, desc = 'Mini Surround: Replace', mode = { 'n' } },
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
