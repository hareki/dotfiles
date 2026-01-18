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

    -- From https://github.com/catppuccin/nvim/blob/main/lua/catppuccin/groups/integrations/dropbar.lua
    -- I just don't like the default colors for kinds, so declare them all myself
    local dropbar_kind_suffixes = {
      'Array',
      'Boolean',
      'BreakStatement',
      'Call',
      'CaseStatement',
      'Class',
      'Constant',
      'Constructor',
      'ContinueStatement',
      'Declaration',
      'Delete',
      'DoStatement',
      'ElseStatement',
      'Enum',
      'EnumMember',
      'Event',
      'Field',
      'File',
      'Folder',
      'ForStatement',
      'Function',
      'Identifier',
      'IfStatement',
      'Interface',
      'Keyword',
      'List',
      'Macro',
      'MarkdownH1',
      'MarkdownH2',
      'MarkdownH3',
      'MarkdownH4',
      'MarkdownH5',
      'MarkdownH6',
      'Method',
      'Module',
      'Namespace',
      'Null',
      'Number',
      'Object',
      'Operator',
      'Package',
      'Property',
      'Reference',
      'Repeat',
      'Scope',
      'Specifier',
      'Statement',
      'String',
      'Struct',
      'SwitchStatement',
      'Type',
      'TypeParameter',
      'Unit',
      'Value',
      'Variable',
      'WhileStatement',
    }
    for _, kind in ipairs(dropbar_kind_suffixes) do
      local group = 'DropBarKind' .. kind
      highlights[group] = highlights[group] or { fg = palette.text }
    end
    return highlights
  end),
  {
    'hareki/dropbar.nvim',
    -- Prevent layout shifting
    lazy = false,
    priority = 500,
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
              Folder = '',
            },
          },
        },

        -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
        -- Intercept and limit the lsp items to avoid too deeply nested items
        bar = {
          enable = require('plugins.ui.dropbar.utils').enable,
          truncate = false,
          hover = true,
          sources = function(buf, _)
            local path_utils = require('utils.path')
            -- The second check is for when one buffer is closed
            local in_diff_view = vim.wo.diff or path_utils.has_dir({ dir_name = '.git' })

            if in_diff_view then
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
              return require('utils.path').get_initial_path()
            end,
          },
        },
      }
    end,
  },
}
