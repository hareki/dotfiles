return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  dependencies = {
    'AndreM222/copilot-lualine',
  },
  init = function()
    if vim.fn.argc(-1) > 0 then
      -- Set an empty statusline till lualine loads
      vim.o.statusline = ' '
    else
      -- Hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    -- PERF: we don't need this lualine require madness 🤷
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local palette = require('utils.ui').get_palette()
    local icons = require('configs.icons')

    local mode_hl = {
      NORMAL = { fg = palette.surface0, bg = palette.blue },
      ['O-PENDING'] = { fg = palette.surface0, bg = palette.blue },

      VISUAL = { fg = palette.base, bg = palette.mauve },
      ['V-LINE'] = { fg = palette.base, bg = palette.mauve },
      ['V-BLOCK'] = { fg = palette.base, bg = palette.mauve },

      SELECT = { fg = palette.base, bg = palette.mauve },
      ['S-LINE'] = { fg = palette.base, bg = palette.mauve },
      ['S-BLOCK'] = { fg = palette.base, bg = palette.mauve },

      INSERT = { fg = palette.base, bg = palette.green },
      SHELL = { fg = palette.base, bg = palette.green },
      TERMINAL = { fg = palette.base, bg = palette.green },

      REPLACE = { fg = palette.base, bg = palette.red },
      ['V-REPLACE'] = { fg = palette.base, bg = palette.red },

      COMMAND = { fg = palette.base, bg = palette.peach },
      EX = { fg = palette.base, bg = palette.peach },
      MORE = { fg = palette.base, bg = palette.peach },
      CONFIRM = { fg = palette.base, bg = palette.peach },
    }

    local theme_reset = {
      normal = {
        a = { fg = palette.surface0, bg = palette.mantle },
        b = { fg = palette.surface0, bg = palette.mantle },
        c = { fg = palette.surface0, bg = palette.mantle },
      },
      insert = {
        a = { fg = palette.surface0, bg = palette.mantle },
        b = { fg = palette.surface0, bg = palette.mantle },
        c = { fg = palette.surface0, bg = palette.mantle },
      },
      visual = {
        a = { fg = palette.surface0, bg = palette.mantle },
        b = { fg = palette.surface0, bg = palette.mantle },
        c = { fg = palette.surface0, bg = palette.mantle },
      },
      replace = {
        a = { fg = palette.surface0, bg = palette.mantle },
        b = { fg = palette.surface0, bg = palette.mantle },
        c = { fg = palette.surface0, bg = palette.mantle },
      },
      inactive = {
        a = { fg = palette.surface0, bg = palette.mantle },
        b = { fg = palette.surface0, bg = palette.mantle },
        c = { fg = palette.surface0, bg = palette.mantle },
      },
    }

    local function inverse_mode_hl(mode)
      local c = mode_hl[mode]
      return { fg = c.bg, bg = c.fg, gui = c.gui }
    end

    -- https://github.com/nvim-lualine/lualine.nvim/blob/a94fc68960665e54408fe37dcf573193c4ce82c9/examples/slanted-gaps.lua#L23
    local empty = require('lualine.component'):extend()
    function empty:draw(default_highlight)
      self.status = ' '
      self.applied_separator = ''
      self:apply_highlights(default_highlight)
      self:apply_section_separators()
      return self.status
    end

    local empty_comp = {
      empty,
      color = { fg = palette.mantle, bg = palette.mantle },
      padding = { left = 0, right = 0 },
      separator = { left = '', right = '' },
    }

    local separator = { left = '', right = '' }
    local git_utils = require('utils.git')

    return {
      options = {
        theme = theme_reset,
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = { statusline = { 'dashboard', 'netrw' } },
        padding = { left = 0, right = 0 },
        sections_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },

      sections = {
        lualine_a = {
          {
            'mode',
            fmt = string.lower,
            icon = {
              -- "󰀵 ",
              ' ',
              color = function()
                local mode = require('lualine.utils.mode').get_mode()
                return mode_hl[mode]
              end,
            },
            separator = separator,
            color = function()
              local mode = require('lualine.utils.mode').get_mode()
              return inverse_mode_hl(mode)
            end,
          },

          empty_comp,

          {
            'filetype',
            icon_only = true,
            colored = false,
            separator = { left = separator.left },
            color = { bg = palette.mauve, fg = palette.mantle },
          },
          {
            'filename',
            fmt = function(filename)
              return filename:gsub('NvimTree_%d+', 'NvimTree')
            end,
            padding = { left = 1 },
            symbols = {
              modified = ' ',
              readonly = '󰌾',
            },
            separator = { right = separator.right },
            color = { fg = palette.mauve, bg = palette.surface0 },
          },
          {
            'branch',
            icon = '',
            fmt = git_utils.format_branch_name,
            color = { fg = palette.subtext0, bg = palette.mantle },
            padding = { left = 2, right = 0 },
          },
          {
            'diff',
            padding = { left = 2, right = 0 },
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {

          {
            'copilot',
            padding = { left = 0, right = 2 },
            color = { fg = palette.subtext0, bg = palette.mantle },
          },

          {
            'diagnostics',
            sections = { 'error', 'warn', 'info' },
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
            always_visible = true,
            padding = { left = 0, right = 2 },
          },

          {
            function()
              return git_utils.get_repo_name()
            end,
            color = { fg = palette.pink, bg = palette.surface0 },
            separator = separator,
            icon = {
              -- "󱉭 ",
              ' ',
              color = { fg = palette.mantle, bg = palette.pink },
            },
            padding = { left = 0, right = 0 },
          },

          empty_comp,

          {
            'progress',
            padding = { left = 0, right = 0 },
            color = { fg = palette.green, bg = palette.surface0 },
            icon = {
              ' ',
              color = { fg = palette.surface0, bg = palette.green },
            },
            separator = separator,
          },
        },
      },
      extensions = { 'neo-tree', 'lazy', 'fzf' },
    }
  end,
}
