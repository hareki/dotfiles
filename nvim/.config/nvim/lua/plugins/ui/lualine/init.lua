return {
  'nvim-lualine/lualine.nvim',

  -- Prevent layout shifting
  lazy = false,
  priority = 500,
  dependencies = { 'hareki/copilot-lualine' },

  enabled = function()
    local lualine_utils = require('plugins.ui.lualine.utils')
    return lualine_utils.have_status_line()
  end,

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
    local buffer_comp = require('plugins.ui.lualine.components.buffer')
    local harpoon_comp = require('plugins.ui.lualine.components.harpoon')
    local macro_comp = require('plugins.ui.lualine.components.macro')
    local mode_comp = require('plugins.ui.lualine.components.mode')
    local progress_comp = require('plugins.ui.lualine.components.progress')
    local diff_comp = require('plugins.ui.lualine.components.diff')

    local icons = require('configs.icons')
    local git_utils = require('utils.git')
    local ui = require('utils.ui')
    local palette = ui.get_palette()

    local lualine_utils = require('plugins.ui.lualine.utils')
    local create_wrapper = lualine_utils.create_styling_wrapper
    local flatten = lualine_utils.flatten_section
    local separator = lualine_utils.separator

    -- PERF: we don't need this lualine require madness 🤷
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
              icons.misc.neovim .. ' ',
              color = mode_comp.icon_color,
            },
            color = mode_comp.color,
          },

          create_wrapper({
            type = 'primary-left',
            color = 'yellow',
            icon = icons.misc.pin,
            comp = harpoon_comp.status,
            cond = harpoon_comp.has_items,
          }),

          create_wrapper({
            type = 'secondary-left',
            comp = 'diff',
            source = diff_comp.source,
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
          }),

          create_wrapper({
            type = 'secondary-left',
            icon = icons.git.branch,
            comp = 'branch',
            fmt = git_utils.format_branch_name,
          }),

          create_wrapper({
            type = 'secondary-left',
            color = 'red',
            icon = icons.misc.macro,
            comp = macro_comp.recording,
            cond = macro_comp.is_recording,
          }),

          create_wrapper({
            type = 'secondary-left',
            comp = buffer_comp.current_buffer_flags,
            color = 'yellow',
          }),

          create_wrapper({
            type = 'secondary-left',
            comp = buffer_comp.global_modified_flag,
            color = 'red',
            padding = { left = 0, right = 0 },
          })
        ),

        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},

        lualine_z = flatten(
          create_wrapper({
            type = 'secondary-right',
            comp = 'copilot',
            symbols = {
              status = {
                icons = {
                  unknown = icons.kinds.CopilotInactive,
                },
              },
              spinners = 'circle_full',
            },
          }),

          create_wrapper({
            type = 'secondary-right',
            comp = 'diagnostics',
            sections = { 'error', 'warn', 'info' },
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          }),

          create_wrapper({
            type = 'primary-right',
            color = 'blue',
            icon = icons.explorer.folder,
            comp = git_utils.get_repo_name,
          }),

          create_wrapper({
            type = 'primary-right',
            color = 'maroon',
            icon = icons.misc.location,
            comp = 'progress',
            fmt = progress_comp.format,
          })
        ),
      },
    }
  end,
}
