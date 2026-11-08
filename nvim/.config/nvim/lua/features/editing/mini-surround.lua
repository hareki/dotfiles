local PREFIX = 'l'

return {
  UI.catppuccin(function()
    return {
      MiniSurround = { link = 'IncSearch' },
    }
  end, 'mini.surround'),

  UI.which_key({
    specs = { PREFIX, group = 'Mini Surround', mode = { 'n', 'x' } },
    rules = { pattern = 'mini.surround', icon = Conf.icons.tools.SURROUND, color = 'purple' },
    -- which-key never auto-triggers the single-letter builtin `l`, which would move the cursor
    triggers = { PREFIX, mode = { 'n', 'x' } },
  }),

  {
    'hareki/mini.surround',
    event = 'VeryLazy',
    opts = function()
      return {
        n_lines = 100,
        highlight_duration = 1000,
        mappings = {
          add = PREFIX .. 'a',
          delete = PREFIX .. 'd',
          replace = PREFIX .. 'r',
          find = PREFIX .. 'f',
          find_left = PREFIX .. 'F',
          highlight = PREFIX .. 'h',
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
