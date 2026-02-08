return {
  Catppuccin(function(palette)
    local highlights = {
      DropBarKindDir = { fg = palette.overlay1 },
      DropBarKindFileBar = { fg = palette.blue, bold = true },
      DropBarIconUIIndicator = { fg = palette.blue, bg = nil },
      DropBarMenuHoverIcon = { link = 'DropBarMenuIcon' }, -- Disable reversing color when hovering
      DropBarIconUISeparator = { fg = palette.overlay1 },
      DropBarMenuHoverEntry = { link = 'Visual' },
      DropBarMenuHoverSymbol = { bold = true },
    }

    local dropbar_utils = require('plugins.ui.dropbar.utils')
    for _, kind in ipairs(dropbar_utils.KIND_SUFFIXES) do
      local group = 'DropBarKind' .. kind
      highlights[group] = highlights[group] or { fg = palette.text }
    end
    return highlights
  end),
  {
    'hareki/dropbar.nvim',
    -- Prevent layout shifting
    lazy = false,
    priority = Priority.LAYOUT,

    keys = {
      {
        '<leader>b',
        function()
          local dropbar_api = require('dropbar.api')
          dropbar_api.pick()
        end,
        desc = 'Dropbar: Pick',
      },
    },

    opts = function()
      local dropbar_utils = require('plugins.ui.dropbar.utils')

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
              Folder = '',
            },
          },
        },

        -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
        -- Intercept and limit the lsp items to avoid too deeply nested items
        bar = {
          enable = dropbar_utils.enable,
          truncate = false,
          hover = true,
          sources = function(buf, _)
            if
              dropbar_utils.is_in_diff_view()
              -- Some ft/bt can slip through the enable check because their ft/bt are set later (E.g. grug-far)
              or dropbar_utils.is_ignored_filetype(buf)
              or dropbar_utils.is_ignored_buftype(buf)
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

            local path_item_limit = 5
            local lsp_item_limit = 6
            local utils = require('dropbar.utils')

            local custom_path = {
              get_symbols = function(b, win, cursor)
                local syms = sources.path.get_symbols(b, win, cursor)
                local start_idx = math.max(1, #syms - path_item_limit + 1)
                local sliced = {}
                if start_idx <= #syms then
                  for i = start_idx, #syms do
                    sliced[#sliced + 1] = syms[i]
                  end
                end
                if #sliced > 0 then
                  -- Set a different highlight group for the last item (the file name) to avoid affecting other places
                  local last = sliced[#sliced]
                  local hl = (win == vim.api.nvim_get_current_win()) and 'DropBarKindFileBar'
                    or 'DropBarKindFileBarNC'
                  last.name_hl = hl
                end
                return sliced
              end,
            }

            local lsp_sources = utils.source.fallback({
              sources.lsp,
            })
            local default_lsp_get_symbols = lsp_sources.get_symbols

            lsp_sources.get_symbols = function(...)
              local symbols = default_lsp_get_symbols(...)
              local limited = {}
              local max_i = math.min(#symbols, lsp_item_limit)
              for i = 1, max_i do
                limited[i] = symbols[i]
              end
              return limited
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
              local path_utils = require('utils.path')
              return path_utils.get_initial_path()
            end,
          },
        },
      }
    end,
  },
}
