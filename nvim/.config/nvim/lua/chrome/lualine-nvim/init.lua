return {
  'nvim-lualine/lualine.nvim',

  enabled = UI.statusline.enabled,

  event = 'VeryLazy',

  init = function()
    local opt = vim.opt

    -- An empty statusline till lualine loads, to prevent layout shifting
    opt.statusline = ' '

    if vim.fn.argc(-1) > 0 then
      return
    end

    -- Hide it on the starter page until a real buffer shows; stdin sessions (`git diff | nvim -`)
    -- report argc 0 too
    opt.laststatus = 0
    vim.api.nvim_create_autocmd({ 'StdinReadPre', 'BufReadPre', 'BufNewFile', 'TermOpen' }, {
      group = vim.api.nvim_create_augroup('chrome.lualine.starter-statusline', { clear = true }),
      once = true,
      callback = function()
        opt.laststatus = 3
      end,
    })
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
    local live_preview = require('chrome.lualine-nvim.components.live-preview')

    local palette = UI.catppuccin.get_palette()

    local lualine_utils = require('chrome.lualine-nvim.utils')
    local create_wrapper = lualine_utils.create_styling_wrapper
    local wrap = lualine_utils.wrap_component
    local flatten = lualine_utils.flatten_section
    local separator = lualine_utils.separator

    -- PERF: we don't need this lualine require madness
    local lualine_require = require('lualine_require')
    lualine_require.require = require

    local color_reset = { fg = palette.subtext1, bg = 'none' }

    return {
      options = {
        -- Modes without an entry fall back to normal
        theme = { normal = { a = color_reset, b = color_reset, c = color_reset } },
        -- options.lua sets laststatus=3 (global statusline); don't derive this
        -- from vim.o.laststatus here, init() may have temporarily set it to 0
        globalstatus = true,
        refresh = { refresh_time = 33 }, -- ~30fps
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

          wrap(harpoon, 'primary-left'),

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

          wrap(macro, 'secondary-left'),

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
          wrap(snacks_image, 'secondary-right'),
          wrap(live_preview, 'secondary-right'),

          create_wrapper({
            comp = 'diagnostics',
            type = 'secondary-right',
            symbols = diagnostics.symbols,
            sections = diagnostics.sections,
            sources = diagnostics.sources,
          }),

          wrap(tab, 'primary-right'),
          wrap(repo_name, 'primary-right', { margin = { left = 0, right = 0 } })
        ),
      },
    }
  end,

  config = function(_, opts)
    local lualine = require('lualine')

    -- lualine.setup turns laststatus on, starter page or not
    local laststatus = vim.o.laststatus
    lualine.setup(opts)
    vim.o.laststatus = laststatus
  end,
}
