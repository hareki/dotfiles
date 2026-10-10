return {
  -- The other DropBarKind* groups come from catppuccin's dropbar integration (core/catppuccin-nvim.lua)
  UI.catppuccin(function(palette)
    return {
      DropBarIconGreen = { fg = palette.green },
      DropBarIconPurple = { fg = palette.mauve },
      DropBarIconYellow = { fg = palette.yellow },

      DropBarKindDir = { fg = palette.overlay2 },
      DropBarKindDirMenu = { fg = palette.blue },
      DropBarKindFileBar = { fg = palette.blue, bold = true },
      DropBarKindFileBarNC = { link = 'DropBarKindFileBar' },

      DropBarIconUIIndicator = { fg = palette.blue },

      DropBarMenuHoverEntry = { link = 'ListCursorLine' },
      DropBarMenuCurrentContext = { link = 'ListCursorLine' },
      DropBarMenuHoverIcon = { link = 'DropBarMenuIcon' }, -- Disable reversing color when hovering
    }
  end, 'dropbar.nvim'),

  UI.which_key({
    rules = { plugin = 'dropbar.nvim', icon = Conf.icons.tools.BREADCRUMB, color = 'purple' },
  }),

  {
    'hareki/dropbar.nvim',
    event = 'VeryLazy',

    init = function()
      local has_cli_args = vim.fn.argc(-1) > 0
      if has_cli_args then
        -- Reserve a winbar line till dropbar loads to prevent layout shifting
        vim.opt.winbar = ' '
      end
    end,

    keys = {
      {
        '<leader>b',
        function()
          local dropbar_api = require('dropbar.api')
          dropbar_api.pick()
        end,
        desc = 'Pick Breadcrumb Item',
      },
    },

    opts = function()
      local dropbar_utils = require('chrome.dropbar-nvim.utils')

      -- Static title bars for plugin UI buffers, by filetype
      local titles = {
        NvimTree = {
          icon = Conf.icons.tools.TREE,
          icon_hl = 'DropBarIconGreen',

          name = ' File Tree',
          name_hl = 'DropBarKindFileBar',
        },
        ['codediff-history'] = {
          icon = Conf.icons.cmp_kinds.History .. ' ',
          icon_hl = 'DropBarIconPurple',

          name = 'Diff History',
          name_hl = 'DropBarKindFileBar',
        },
        ['codediff-explorer'] = {
          icon = Conf.icons.git.DIFF .. ' ',
          icon_hl = 'DropBarIconYellow',

          name = 'Diff Explorer',
          name_hl = 'DropBarKindFileBar',
        },
      }

      return {
        menu = {
          preview = false,
          win_configs = {
            border = 'rounded',
          },
        },
        icons = {
          ui = {
            menu = {
              indicator = ' ' .. Conf.icons.file_tree.COLLAPSED .. ' ',
            },
          },
          kinds = {
            symbols = {
              Folder = '',
              FolderMenu = Conf.icons.file_tree.FOLDER .. ' ',
              FolderEmptyMenu = Conf.icons.file_tree.FOLDER_EMPTY .. ' ',
              FolderOpenMenu = Conf.icons.file_tree.FOLDER_OPEN .. ' ',
            },
          },
        },

        -- https://github.com/Bekaboo/dropbar.nvim?tab=readme-ov-file#bar
        bar = {
          enable = dropbar_utils.enable,
          truncate = false,
          sources = function(buf, win)
            -- Some ft/bt can slip through the enable check because their ft/bt are set later (E.g. grug-far)
            if dropbar_utils.is_ignored_filetype(buf) or dropbar_utils.is_ignored_buftype(buf) then
              vim.wo[win].winbar = ''
              return {}
            end

            local sources = require('dropbar.sources')

            local title = titles[vim.bo[buf].filetype]
            if title then
              return dropbar_utils.title_symbol(title)
            end

            local custom_path = {
              get_symbols = function(b, w, cursor)
                --- @type dropbar_symbol_t[]
                local syms = sources.path.get_symbols(b, w, cursor)
                if #syms > 0 then
                  -- Set a different highlight group for the last item (the file name) to avoid affecting other places
                  local last = syms[#syms]
                  local hl = (w == vim.api.nvim_get_current_win()) and 'DropBarKindFileBar'
                    or 'DropBarKindFileBarNC'
                  last.name_hl = hl
                end
                return syms
              end,
            }

            return {
              custom_path,
              vim.bo[buf].filetype == 'markdown' and sources.markdown or sources.lsp,
            }
          end,
        },

        sources = {
          path = {
            -- The path is walked up from the file, so this keeps its innermost segments
            max_depth = 5,
            relative_to = function()
              local path_utils = require('utils.path')
              return path_utils.get_initial_path()
            end,

            filter = function(name)
              return name ~= '.DS_Store'
            end,
          },
          lsp = {
            max_depth = 6, -- Limit the lsp items to avoid too deeply nested items
          },
        },
      }
    end,

    config = function(_, opts)
      -- Clear the placeholder before dropbar's own per-window enable check
      -- runs, otherwise it reads back as already-claimed and never attaches
      vim.opt.winbar = ''
      local dropbar = require('dropbar')
      dropbar.setup(opts)
    end,
  },
}
