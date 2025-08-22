return {
  'Bekaboo/dropbar.nvim',
  event = 'LazyFile',
  dependencies = {
    'nvim-telescope/telescope-fzf-native.nvim',
  },

  keys = function(_, keys)
    local dropbar_pick_key = '<leader>b'
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

  opts = {
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
      kinds = {
        symbols = {
          Folder = '',
        },
      },
    },

    -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
    -- intercept and limit the lsp items to avoid too deeply nested items
    bar = {
      truncate = false,
      hover = true,
      sources = function(buf, _)
        -- Hide the dropbar when in diff view
        -- The second check is for when one buffer is closed
        if
          vim.wo.diff
          or require('utils.path').has_dir({
            dir_name = '.git',
          })
        then
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

        local path_item_limit = 5
        local lsp_item_limit = 4
        local utils = require('dropbar.utils')

        -- Limit path sources to 3 nearest parent directories
        local path_sources = sources.path
        local orig_path_get_symbols = path_sources.get_symbols

        path_sources.get_symbols = function(...)
          local symbols = orig_path_get_symbols(...)
          -- Take the last 3 items (nearest parent directories)
          local start_idx = math.max(1, #symbols - path_item_limit + 1)
          return { unpack(symbols, start_idx, #symbols) }
        end

        local lsp_sources = utils.source.fallback({
          sources.lsp,
          sources.treesitter,
        })
        local orig_lsp_get_symbols = lsp_sources.get_symbols

        lsp_sources.get_symbols = function(...)
          local symbols = orig_lsp_get_symbols(...)
          return { unpack(symbols, 1, math.min(#symbols, lsp_item_limit)) }
        end

        return {
          path_sources,
          lsp_sources,
        }
      end,
    },

    sources = {
      path = {
        relative_to = function()
          return require('utils.path').get_initial_path()
        end,
      },
    },
  },
}
