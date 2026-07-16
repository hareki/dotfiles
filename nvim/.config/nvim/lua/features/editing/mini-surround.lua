local prefix = 'l'

return {
  UI.catppuccin(function()
    return {
      MiniSurround = { link = 'IncSearch' },
    }
  end, 'mini.surround'),

  UI.which_key({
    specs = { prefix, group = 'Mini Surround', mode = { 'n', 'x' } },
    rules = { pattern = 'mini.surround', icon = Conf.icons.tools.SURROUND, color = 'purple' },
    -- `l` is a single-letter builtin which-key never auto-triggers; register it
    -- manually so pressing `l` holds the prefix instead of moving the cursor right.
    triggers = { prefix, mode = { 'n', 'x' } },
  }),

  {
    'hareki/mini.surround',
    event = 'VeryLazy',
    opts = function()
      return {
        n_lines = 100,
        highlight_duration = 1000,
        mappings = {
          add = prefix .. 'a',
          delete = prefix .. 'd',
          replace = prefix .. 'r',
          find = prefix .. 'f',
          find_left = prefix .. 'F',
          highlight = prefix .. 'h',
        },
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
