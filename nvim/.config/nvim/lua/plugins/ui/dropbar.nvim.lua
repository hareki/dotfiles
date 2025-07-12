return {
  'Bekaboo/dropbar.nvim',
  event = 'LazyFile',
  dependencies = {
    'nvim-telescope/telescope-fzf-native.nvim',
  },

  keys = function(_, keys)
    local dropbar_pick_key = '<leader>d'
    local wk = require('which-key')

    wk.add({
      {
        dropbar_pick_key,
        icon = '',
      },
    })

    return vim.list_extend(keys, {
      { dropbar_pick_key, "<cmd>lua require('dropbar.api').pick()<cr>", desc = 'Dropbar pick' },
    })
  end,

  opts = function(_, opts)
    Util.highlights({
      DropBarKindDir = { link = 'DropBarKindFile' },
    })

    return vim.tbl_deep_extend('force', opts, {
      menu = {
        win_configs = {
          border = 'rounded',
        },
      },
      icons = {
        ui = {
          menu = {
            indicator = '',
          },
        },
      },

      -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
      -- intercept and limit the lsp items to avoid too deeply nested items
      bar = {
        truncate = false,
        hover = false,
        sources = function(buf, _)
          -- Hide the dropbar when in diff view
          -- The second check is for when one buffer is closed
          if vim.wo.diff or Util.has_dir({
            dir_name = '.git',
          }) then
            vim.wo.winbar = ''
            return {}
          end

          local sources = require('dropbar.sources')

          if vim.bo[buf].ft == 'markdown' then
            return {
              sources.path,
              sources.markdown,
            }
          end
          if vim.bo[buf].buftype == 'terminal' then
            return {
              sources.terminal,
            }
          end

          -- return {
          --   sources.path,
          -- }

          local lsp_item_limit = 3
          local utils = require('dropbar.utils')

          local lsp_sources = utils.source.fallback({
            sources.lsp,
            sources.treesitter,
          })
          local orig_get_symbols = lsp_sources.get_symbols

          lsp_sources.get_symbols = function(...)
            local symbols = orig_get_symbols(...)
            return { unpack(symbols, 1, math.min(#symbols, lsp_item_limit)) }
          end

          return {
            sources.path,
            lsp_sources,
          }
        end,
      },

      sources = {
        path = {
          relative_to = function()
            return Util.get_initial_path()
          end,
        },
      },
    })
  end,
}
