return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  dependencies = {
    'AndreM222/copilot-lualine',
  },
  init = function()
    if vim.env.NVIM_NO_STATUS_LINE then
      vim.o.laststatus = 0
      return
    end

    if vim.fn.argc(-1) > 0 then
      -- Set an empty statusline till lualine loads
      vim.o.statusline = ' '
    else
      -- Hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  enabled = function()
    return require('plugins.ui.lualine.util').have_status_line()
  end,
  opts = function()
    -- PERF: we don't need this lualine require madness 🤷
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local palette = require('utils.ui').get_palette()
    local icons = require('configs.icons')

    local mode_hl = {}
    for _, mode in ipairs({ 'NORMAL', 'O-PENDING' }) do
      mode_hl[mode] = { fg = palette.surface0, bg = palette.blue }
    end
    for _, mode in ipairs({ 'VISUAL', 'V-LINE', 'V-BLOCK', 'SELECT', 'S-LINE', 'S-BLOCK' }) do
      mode_hl[mode] = { fg = palette.base, bg = palette.mauve }
    end
    for _, mode in ipairs({ 'INSERT', 'SHELL', 'TERMINAL' }) do
      mode_hl[mode] = { fg = palette.base, bg = palette.green }
    end
    for _, mode in ipairs({ 'REPLACE', 'V-REPLACE' }) do
      mode_hl[mode] = { fg = palette.base, bg = palette.red }
    end
    for _, mode in ipairs({ 'COMMAND', 'EX', 'MORE', 'CONFIRM' }) do
      mode_hl[mode] = { fg = palette.base, bg = palette.peach }
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
            require('utils.tab').lualine,
            icon = {
              icons.misc.tab,
              color = { fg = palette.base, bg = palette.mauve },
            },
            separator = { left = separator.left, right = separator.right },
            color = { fg = palette.mauve, bg = palette.surface0 },
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
          {
            'branch',
            icon = '',
            fmt = git_utils.format_branch_name,
            color = { fg = palette.subtext0, bg = palette.base },
            padding = { left = 2, right = 0 },
          },
          {
            require('utils.buffer').lualine,
            padding = { left = 2, right = 0 },
            color = { fg = palette.peach },
          },
        },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {

          {
            'copilot',
            symbols = {
              spinners = icons.misc.spinner_frames,
            },
            padding = { left = 0, right = 2 },
            color = { fg = palette.subtext0, bg = palette.base },
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
              color = { fg = palette.base, bg = palette.pink },
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
    }
  end,
}
