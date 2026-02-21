return {
  'nvim-lualine/lualine.nvim',

  lazy = false,
  priority = Priority.CHROME,
  dependencies = { 'AndreM222/copilot-lualine' },

  enabled = function()
    local lualine_utils = require('services.statusline')
    return lualine_utils.have_status_line()
  end,

  init = function()
    local opt = vim.opt

    opt.showcmd = true -- Show pending keys/command
    opt.showcmdloc = 'statusline'

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
    local buffer_status = require('plugins.chrome.lualine.components.buffer_status')
    local harpoon = require('plugins.chrome.lualine.components.harpoon')
    local macro = require('plugins.chrome.lualine.components.macro')
    local mode = require('plugins.chrome.lualine.components.mode')
    local progress = require('plugins.chrome.lualine.components.progress')
    local diff = require('plugins.chrome.lualine.components.diff')
    local copilot = require('plugins.chrome.lualine.components.copilot')
    local diagnostics = require('plugins.chrome.lualine.components.diagnostics')
    local repo_name = require('plugins.chrome.lualine.components.repo_name')
    local branch = require('plugins.chrome.lualine.components.branch')
    local pending_keys = require('plugins.chrome.lualine.components.pending_keys')

    local ui = require('utils.ui')
    local palette = ui.get_palette()

    local lualine_utils = require('plugins.chrome.lualine.utils')
    local create_wrapper = lualine_utils.create_styling_wrapper
    local flatten = lualine_utils.flatten_section
    local separator = lualine_utils.separator

    -- PERF: we don't need this lualine require madness
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local theme_reset = {}
    local color_reset = { fg = palette.subtext1, bg = palette.base }
    for _, section in ipairs({ 'normal', 'insert', 'visual', 'replace', 'inactive' }) do
      theme_reset[section] = { a = color_reset, b = color_reset, c = color_reset }
    end

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
        lualine_a = flatten(
          {
            'mode',
            separator = separator,
            fmt = string.lower,
            icon = {
              Icons.misc.neovim .. ' ',
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

        lualine_z = flatten(
          create_wrapper({
            comp = pending_keys.get,
            type = 'secondary-right',
            icon = pending_keys.icon,
            cond = pending_keys.cond,
          }),

          create_wrapper({
            comp = 'copilot',
            type = 'secondary-right',
            symbols = copilot.symbols,
            padding = copilot.padding,
          }),

          create_wrapper({
            comp = 'diagnostics',
            type = 'secondary-right',
            symbols = diagnostics.symbols,
            sections = diagnostics.sections,
          }),

          create_wrapper({
            comp = repo_name.get,
            type = 'primary-right',
            color = 'blue',
            icon = repo_name.icon,
          }),

          create_wrapper({
            comp = 'progress',
            type = 'primary-right',
            color = 'maroon',
            icon = progress.icon,
            fmt = progress.format,
            margin = { left = 0, right = 0 },
          })
        ),
      },
    }
  end,
}
