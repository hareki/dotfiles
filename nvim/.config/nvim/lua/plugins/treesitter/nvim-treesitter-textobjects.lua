return {
  'nvim-treesitter/nvim-treesitter-textobjects',
  branch = 'main',
  event = 'VeryLazy',
  opts = {
    move = {
      enable = true,
      set_jumps = true,
      keys = {
        goto_next_start = {
          [']f'] = {
            query = '@function.outer',
            desc = 'Goto Next Function Start',
          },
          [']c'] = {
            query = '@class.outer',
            desc = 'Goto Next Class Start',
          },
          [']a'] = {
            query = '@parameter.inner',
            desc = 'Goto Next Parameter Start',
          },
        },
        goto_next_end = {
          [']F'] = {
            query = '@function.outer',
            desc = 'Goto Next Function End',
          },
          [']C'] = {
            query = '@class.outer',
            desc = 'Goto Next Class End',
          },
          [']A'] = {
            query = '@parameter.inner',
            desc = 'Goto Next Parameter End',
          },
        },
        goto_previous_start = {
          ['[f'] = {
            query = '@function.outer',
            desc = 'Goto Previous Function Start',
          },
          ['[c'] = {
            query = '@class.outer',
            desc = 'Goto Previous Class Start',
          },
          ['[a'] = {
            query = '@parameter.inner',
            desc = 'Goto Previous Parameter Start',
          },
        },
        goto_previous_end = {
          ['[F'] = {
            query = '@function.outer',
            desc = 'Goto Previous Function End',
          },
          ['[C'] = {
            query = '@class.outer',
            desc = 'Goto Previous Class End',
          },
          ['[A'] = {
            query = '@parameter.inner',
            desc = 'Goto Previous Parameter End',
          },
        },
      },
    },
  },
  config = function(_, opts)
    local TS = require('nvim-treesitter-textobjects')
    TS.setup(opts)

    local function attach(buf)
      if not (vim.tbl_get(opts, 'move', 'enable')) then
        return
      end

      ---@type table<string, table<string, string>>
      local moves = vim.tbl_get(opts, 'move', 'keys') or {}

      for method, keymaps in pairs(moves) do
        for key, query in pairs(keymaps) do
          local queries = type(query) == 'table' and query or { query }
          local parts = {}
          for _, q in ipairs(queries) do
            local part = q:gsub('@', ''):gsub('%..*', '')
            part = part:sub(1, 1):upper() .. part:sub(2)
            table.insert(parts, part)
          end
          local desc = table.concat(parts, ' or ')
          desc = (key:sub(1, 1) == '[' and 'Prev ' or 'Next ') .. desc
          desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and ' End' or ' Start')
          if not (vim.wo.diff and key:find('[cC]')) then
            vim.keymap.set({ 'n', 'x', 'o' }, key, function()
              require('nvim-treesitter-textobjects.move')[method](query, 'textobjects')
            end, {
              buffer = buf,
              desc = desc,
              silent = true,
            })
          end
        end
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('lazyvim_treesitter_textobjects', { clear = true }),
      callback = function(ev)
        attach(ev.buf)
      end,
    })

    vim.tbl_map(attach, vim.api.nvim_list_bufs())
  end,
}
