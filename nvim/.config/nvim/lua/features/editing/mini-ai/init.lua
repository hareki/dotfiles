return {
  'hareki/mini.ai',
  event = 'VeryLazy',
  dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
  opts = function()
    local mini_ai = require('mini.ai')
    local utils = require('features.editing.mini-ai.utils')

    return {
      n_lines = 500,
      custom_textobjects = {
        o = mini_ai.gen_spec.treesitter({ -- code block
          a = { '@block.outer', '@conditional.outer', '@loop.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner' },
        }),
        f = mini_ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
        c = mini_ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }),
        t = mini_ai.gen_spec.treesitter({ a = '@tag.outer', i = '@tag.inner' }),
        d = { '%f[%d]%d+' }, -- digits
        w = {
          {
            -- ALL-CAPS segments with digits ("HTTP2", "JSON" in "parseJSON"); frontier patterns
            -- can't split a leading acronym off a camel chunk ("XML" in "XMLHttpRequest")
            '%f[%u%d][%u%d]+%f[^%a%d]',

            -- Pascal/Camel subwords, e.g. "Http" in "XMLHttp"
            '%u[%l%d]+%f[^%l%d]',

            -- Lower/digit segments (snake parts like "constant" or "case2")
            '%f[%a%d][%l%d]+%f[^%l%d]',

            -- Pure digit runs
            '%f[%d]%d+%f[^%d]',
          },
          '^().*()$',
        },
        W = {
          {
            -- Whole snake/scream chunk (letters/digits connected by underscores)
            '%f[%w_][%w_]+%f[^%w_]',
          },
          '^().*()$',
        },
        g = utils.buffer,
        u = mini_ai.gen_spec.function_call(), -- u for "Usage"
        U = mini_ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
      },
    }
  end,
  config = function(_, opts)
    local mini_ai = require('mini.ai')
    local utils = require('features.editing.mini-ai.utils')

    utils.setup_repeat()
    mini_ai.setup(opts)
    utils.whichkey()
  end,
}
