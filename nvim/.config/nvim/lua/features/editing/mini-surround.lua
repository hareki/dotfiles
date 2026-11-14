local KEY_PREFIX = 'l'

return {
  UI.catppuccin(function()
    return {
      MiniSurround = { link = 'IncSearch' },
    }
  end, 'mini.surround'),

  UI.which_key({
    specs = { KEY_PREFIX, group = 'Mini Surround', mode = { 'n', 'x' } },
    rules = { pattern = 'mini.surround', icon = Conf.icons.tools.SURROUND, color = 'mauve' },
    -- which-key never auto-triggers the single-letter builtin `l`, which would move the cursor
    triggers = { KEY_PREFIX, mode = { 'n', 'x' } },
  }),

  {
    'hareki/mini.surround',
    event = 'VeryLazy',
    opts = function()
      return {
        n_lines = 100,
        highlight_duration = 1000,
        mappings = {
          add = KEY_PREFIX .. 'a',
          delete = KEY_PREFIX .. 'd',
          replace = KEY_PREFIX .. 'r',
          find = KEY_PREFIX .. 'f',
          find_left = KEY_PREFIX .. 'F',
          highlight = KEY_PREFIX .. 'h',
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
