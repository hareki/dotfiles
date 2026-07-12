return {
  'nvim-lualine/lualine.nvim',

  enabled = function()
    return UI.statusline.enabled()
  end,

  lazy = false,
  priority = Conf.priority.CHROME,

  init = function()
    local opt = vim.opt

    local has_cli_args = vim.fn.argc(-1) > 0
    if has_cli_args then
      -- Set an empty statusline till lualine loads to prevent layout shifting
      opt.statusline = ' '
    else
      -- Hide the statusline on the starter page
      opt.laststatus = 0
    end
  end,

  opts = function()
    local buffer_status = require('chrome.lualine-nvim.components.buffer-status')
    local harpoon = require('chrome.lualine-nvim.components.harpoon')
    local macro = require('chrome.lualine-nvim.components.macro')
    local mode = require('chrome.lualine-nvim.components.mode')
    local diff = require('chrome.lualine-nvim.components.diff')
    local diagnostics = require('chrome.lualine-nvim.components.diagnostics')
    local repo_name = require('chrome.lualine-nvim.components.repo-name')
    local branch = require('chrome.lualine-nvim.components.branch')
    local tab = require('chrome.lualine-nvim.components.tab')
    local snacks_image = require('chrome.lualine-nvim.components.snacks-image')

    local palette = UI.catppuccin.get_palette()

    local lualine_utils = require('chrome.lualine-nvim.utils')
    local create_wrapper = function(opts)
      opts.palette = palette
      return lualine_utils.create_styling_wrapper(opts)
    end
    local flatten = lualine_utils.flatten_section
    local separator = lualine_utils.separator

    -- PERF: we don't need this lualine require madness
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local theme_reset = {}
    local color_reset = { fg = palette.subtext1, bg = 'none' }
    for _, section in ipairs({ 'normal', 'insert', 'visual', 'replace', 'inactive' }) do
      theme_reset[section] = { a = color_reset, b = color_reset, c = color_reset }
    end

    local lualine_z_components = {
      create_wrapper({
        comp = snacks_image.get,
        type = 'secondary-right',
        color = 'green',
        cond = snacks_image.cond,
      }),
      create_wrapper({
        comp = 'diagnostics',
        type = 'secondary-right',
        symbols = diagnostics.symbols,
        sections = diagnostics.sections,
        sources = diagnostics.sources,
      }),
      create_wrapper({
        comp = tab.get,
        type = 'primary-right',
        color = 'green',
        icon = tab.icon,
        cond = tab.cond,
      }),
      create_wrapper({
        comp = repo_name.get,
        type = 'primary-right',
        color = 'blue',
        icon = repo_name.icon,
        margin = { left = 0, right = 0 },
      }),
    }

    return {
      options = {
        theme = theme_reset,
        globalstatus = vim.o.laststatus == 3,
        refresh = { refresh_time = 33 }, -- ~30fps
        disabled_filetypes = { statusline = { 'dashboard', 'netrw' } },
        padding = { left = 0, right = 0 },
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },

      sections = {
        lualine_a = flatten(
          {
            'mode',
            separator = separator,
            fmt = string.lower,
            icon = {
              Conf.icons.misc.NEOVIM .. ' ',
              color = mode.icon_color,
            },
            color = mode.color,
          },

          create_wrapper({
            comp = harpoon.get,
            type = 'primary-left',
            color = 'yellow',
            icon = harpoon.icon,
            cond = harpoon.cond,
          }),

          create_wrapper({
            comp = 'diff',
            type = 'secondary-left',
            symbols = diff.symbols,
            source = diff.source,
          }),

          create_wrapper({
            comp = 'branch',
            type = 'secondary-left',
            icon = branch.icon,
            fmt = branch.format,
          }),

          create_wrapper({
            comp = macro.get,
            type = 'secondary-left',
            color = 'red',
            icon = macro.icon,
            cond = macro.cond,
          }),

          create_wrapper({
            comp = buffer_status,
            type = 'secondary-left',
          })
        ),

        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},

        lualine_z = flatten(unpack(lualine_z_components)),
      },
    }
  end,
}
