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
    local component_path = 'plugins.ui.lualine.components.'
    local buffer_comp = require(component_path .. 'buffer')
    local harpoon_comp = require(component_path .. 'harpoon')
    local macro_comp = require(component_path .. 'macro')
    local progress_comp = require(component_path .. 'progress')

    local lualine_utils = require('plugins.ui.lualine.utils')
    local create_wrapper = lualine_utils.create_styling_wrapper
    local separator = lualine_utils.separator

    -- PERF: we don't need this lualine require madness 🤷
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local ui = require('utils.ui')
    local palette = ui.get_palette()
    local icons = require('configs.icons')

    local mode_hl = {}
    for _, mode in ipairs({ 'NORMAL', 'O-PENDING' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.blue }
    end
    for _, mode in ipairs({ 'VISUAL', 'V-LINE', 'V-BLOCK', 'SELECT', 'S-LINE', 'S-BLOCK' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.mauve }
    end
    for _, mode in ipairs({ 'INSERT', 'SHELL', 'TERMINAL' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.green }
    end
    for _, mode in ipairs({ 'REPLACE', 'V-REPLACE' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.red }
    end
    for _, mode in ipairs({ 'COMMAND', 'EX', 'MORE', 'CONFIRM' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.peach }
    end

    local theme_reset = {}
    local color_reset = { fg = palette.subtext1, bg = palette.base }
    for _, section in ipairs({ 'normal', 'insert', 'visual', 'replace', 'inactive' }) do
      theme_reset[section] = { a = color_reset, b = color_reset, c = color_reset }
    end

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
      color = { fg = palette.base, bg = palette.base },
      padding = { left = 0, right = 0 },
      separator = { left = '', right = '' },
    }

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
            separator = separator,
            fmt = string.lower,

            icon = {
              icons.misc.neovim .. ' ',
              color = function()
                local mode_utils = require('lualine.utils.mode')
                local mode = mode_utils.get_mode()
                return mode_hl[mode]
              end,
            },
            color = function()
              local mode_utils = require('lualine.utils.mode')
              local mode = mode_utils.get_mode()
              return inverse_mode_hl(mode)
            end,
          },

          empty_comp,

          create_wrapper({
            type = 'primary',
            color = 'yellow',
            icon = icons.misc.pin,
            comp = harpoon_comp.harpoon_status,
          }),

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

          create_wrapper({
            type = 'secondary',
            icon = icons.git.branch,
            comp = 'branch',
            fmt = git_utils.format_branch_name,
          }),

          create_wrapper({
            type = 'secondary',
            color = 'red',
            icon = ' ',
            comp = macro_comp.recording,
            cond = macro_comp.is_recording,
          }),

          empty_comp,
          empty_comp,

          {
            buffer_comp.current_buffer_flags,
            padding = { left = 0, right = 0 },
            color = { fg = palette.yellow },
          },
          {
            buffer_comp.global_modified_flag,
            padding = { left = 0, right = 0 },
            color = { fg = palette.red },
          },
        },

        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},

        lualine_z = {
          {
            'copilot',
            padding = { left = 2, right = 0 },
            color = { fg = palette.subtext0, bg = palette.base },

            symbols = {
              status = {
                icons = {
                  unknown = icons.kinds.CopilotInactive,
                },
              },
              spinners = 'circle_full',
            },
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
            -- always_visible = true,
            padding = { left = 2, right = 0 },
          },

          -- Hack to workaround the fact that copilot and sidekick.cli count are two separate components
          -- NOTE: temporarily remove sidekick.nvim but keep this just in case
          empty_comp,
          empty_comp,

          create_wrapper({
            type = 'primary',
            color = 'blue',
            icon = icons.explorer.folder,
            comp = git_utils.get_repo_name,
          }),

          empty_comp,

          create_wrapper({
            type = 'primary',
            color = 'maroon',
            icon = icons.misc.location,
            comp = 'progress',
            fmt = progress_comp.format,
          }),
        },
      },
    }
  end,
}
