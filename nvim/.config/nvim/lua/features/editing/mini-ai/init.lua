local last_obj

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
        f = mini_ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }), -- function
        c = mini_ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }), -- class
        t = mini_ai.gen_spec.treesitter({ a = '@tag.outer', i = '@tag.inner' }), -- tags
        d = { '%f[%d]%d+' }, -- digits
        w = {
          {
            -- Acronyms / ALL-CAPS segments (incl. digits), e.g. "CONSTANT", "HTTP2",
            -- and trailing acronyms like "JSON" in "parseJSON". A leading acronym
            -- glued to a camel chunk ("XML" in "XMLHttpRequest") is still not
            -- expressible with Lua frontier patterns; the camel pattern below
            -- picks up "Http"-style chunks instead
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

    vim.api.nvim_create_autocmd('User', {
      group = vim.api.nvim_create_augroup('editing.mini-ai.record-last-object', { clear = true }),
      pattern = 'MiniAiSelectObject',
      callback = function(ev)
        last_obj = ev.data -- "iw", "af", "g", ...
      end,
    })

    vim.keymap.set('x', '.', function()
      if last_obj then
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes(last_obj, true, false, true), -- translate <Esc>, <CR> …
          'x',
          false -- not literally; integrate with typeahead
        )
      end
    end, { desc = 'Repeat Last Text-Object Selection' })

    mini_ai.setup(opts)

    local package_utils = require('utils.package')
    local utils = require('features.editing.mini-ai.utils')

    package_utils.on_load('which-key.nvim', function()
      vim.schedule(function()
        utils.whichkey(opts)
      end)
    end)
  end,
}
