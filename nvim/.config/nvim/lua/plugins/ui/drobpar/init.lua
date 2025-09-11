return {
  require('utils.ui').catppuccin(function(palette)
    return {
      DropBarKindDir = { fg = palette.text },
      DropBarKindFileBar = { fg = palette.yellow, bold = true },
      DropBarIconUIIndicator = { fg = palette.blue, bg = nil },
      DropBarMenuHoverIcon = { link = 'DropBarMenuIcon' }, -- Disable reversing color when hovering
    }
  end),
  {
    'hareki/dropbar.nvim',
    event = 'LazyFile',
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
    },

    keys = {
      {
        '<leader>b',
        function()
          require('dropbar.api').pick()
        end,
        desc = 'Dropbar: Pick',
      },
    },

    opts = function()
      return {
        menu = {
          indicator_side = 'right',
          preview = false,
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
              -- Folder = '',
            },
          },
        },

        -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
        -- intercept and limit the lsp items to avoid too deeply nested items
        bar = {
          enable = require('plugins.ui.drobpar.utils').enable,
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
              return {}
            end

            -- return {
            --   sources.path,
            -- }

            local path_item_limit = 5
            local lsp_item_limit = 4
            local utils = require('dropbar.utils')

            local custom_path = {
              get_symbols = function(b, win, cursor)
                local syms = sources.path.get_symbols(b, win, cursor)
                local start_idx = math.max(1, #syms - path_item_limit + 1)
                syms = { unpack(syms, start_idx, #syms) }
                if #syms > 0 then
                  -- Set a different highlight group for the last item (the file name) to avoid affecting other places
                  local last = syms[#syms]
                  local hl = (win == vim.api.nvim_get_current_win()) and 'DropBarKindFileBar'
                    or 'DropBarKindFileBarNC'
                  last.name_hl = hl
                end
                return syms
              end,
            }

            local lsp_sources = utils.source.fallback({
              sources.lsp,
              sources.treesitter,
            })
            local default_lsp_get_symbols = lsp_sources.get_symbols

            lsp_sources.get_symbols = function(...)
              local symbols = default_lsp_get_symbols(...)
              return { unpack(symbols, 1, math.min(#symbols, lsp_item_limit)) }
            end

            return {
              custom_path,
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
      }
    end,
  },
}
