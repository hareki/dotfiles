local last_obj

return {
  'hareki/mini.ai',
  event = 'VeryLazy',
  opts = function()
    local ai = require('mini.ai')
    local utils = require('plugins.coding.mini-ai.utils')

    vim.api.nvim_create_autocmd('User', {
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
    end, { desc = 'Repeat Last text-object Selection' })

    return {
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({ -- code block
          a = { '@block.outer', '@conditional.outer', '@loop.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner' },
        }),
        f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }), -- function
        c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }), -- class
        t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
        d = { '%f[%d]%d+' }, -- digits
        w = {
          {
            -- Acronyms / ALL-CAPS segments (incl. digits)
            -- e.g. "CONSTANT", "HTTP2"
            '%f[%a%d]%u+%f[^%a%d]',
            -- Acronym directly before CamelCase chunk
            -- e.g. "XML" in "XMLHttpRequest"
            '%f[%a%d]%u+%f[%u]',

            -- Pascal/Camel subwords
            -- e.g. "Http" in "XMLHttp"
            '%u[%l%d]+%f[^%l%d]',

            -- lower/digit segments (snake parts like "constant" or "case2")
            '%f[%a%d][%l%d]+%f[^%l%d]',

            -- pure digit runs
            '%f[%d]%d+%f[^%d]',
          },
          '^().*()$',
        },
        W = {
          {
            -- whole snake/scream chunk (letters/digits connected by underscores)
            '%f[^_][%w]+_%w+[%w_]*%f[^%w_]', -- at least one underscore
            '%f[%w][%w]+%f[^%w]', -- single chunk fallback
          },
          '^().*()$',
        },
        g = utils.buffer,
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
      },
    }
  end,
  config = function(_, opts)
    require('mini.ai').setup(opts)
    local packgage_utils = require('utils.package')
    local utils = require('plugins.coding.mini-ai.utils')

    packgage_utils.on_load('which-key.nvim', function()
      vim.schedule(function()
        utils.whichkey(opts)
      end)
    end)
  end,
}
