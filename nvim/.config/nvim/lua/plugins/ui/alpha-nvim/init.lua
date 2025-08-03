return {
  'goolord/alpha-nvim',
  enabled = true,
  event = 'VimEnter',
  opts = function()
    local ui_utils = require('utils.ui')
    local palette = ui_utils.get_palette()
    local utils = require('plugins.ui.alpha-nvim.utils')

    ui_utils.set_highlights({
      AlphaHeader = { fg = palette.blue },
      AlphaStats = { fg = palette.yellow },
      AlphaTitle = { fg = palette.blue },
      AlphaItem = { fg = palette.text },
      AlphaQuote = { fg = palette.green, italic = true },
    })

    local vertical_offset = {
      type = 'padding',
      val = 0,
    }

    local header = {
      type = 'text',
      val = {
        [[                                                                     ]],
        [[       ████ ██████           █████      ██                     ]],
        [[      ███████████             █████                             ]],
        [[      █████████ ███████████████████ ███   ███████████   ]],
        [[     █████████  ███    █████████████ █████ ██████████████   ]],
        [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
        [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
        [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
      },
      opts = {
        position = 'center',
        hl = 'AlphaHeader',
      },
    }

    local stats = {
      type = 'text',
      val = '',
      opts = {
        position = 'center',
        hl = 'AlphaStats',
      },
    }

    local projects = {
      type = 'group',
      opts = {},
      val = {
        {
          type = 'text',
          val = '󰪺 Projects',
          opts = { position = 'center', hl = 'AlphaTitle', shrink_margin = false },
        },

        {
          type = 'group',
          val = utils.get_recent_projects(),
        },
      },
    }

    local files = {
      type = 'group',
      val = {
        {
          type = 'text',
          val = '󰪺 Files',
          opts = { position = 'center', hl = 'AlphaTitle', shrink_margin = false },
        },

        {
          type = 'group',
          val = utils.get_recent_files(),
        },
      },
    }

    local quote = {
      type = 'group',
      val = utils.get_random_quote(),
    }

    local section = {
      vertical_offset = vertical_offset,
      header = header,
      stats = stats,
      projects = projects,
      files = files,
      quote = quote,
    }

    local config = {
      layout = {
        section.vertical_offset,
        section.header,
        { type = 'padding', val = 1 },
        section.stats,
        { type = 'padding', val = 1 },
        section.projects,
        { type = 'padding', val = 1 },
        section.files,
        { type = 'padding', val = 1 },
        section.quote,
      },

      opts = {
        noautocmd = true,
      },
    }

    return {
      config = config,
      section = section,
    }
  end,
  config = function(_, dashboard)
    local utils = require('plugins.ui.alpha-nvim.utils')

    vim.api.nvim_create_autocmd('User', {
      once = true,
      pattern = 'AlphaReady',
      callback = function(ev)
        local alpha_buf = ev.buf
        local map = vim.keymap.set

        map({ 'n', 'v' }, '<PageUp>', '<C-u>', { desc = 'Scroll up', buffer = alpha_buf })
        map({ 'n', 'v' }, '<PageDown>', '<C-d>', { desc = 'Scroll down', buffer = alpha_buf })
      end,
    })

    require('alpha').setup(dashboard.config)

    vim.api.nvim_create_autocmd('User', {
      once = true,
      pattern = 'LazyVimStarted',
      callback = function()
        dashboard.section.stats.val = utils.get_stats()
        dashboard.section.vertical_offset.val = utils.get_vertical_offset()

        pcall(vim.cmd.AlphaRedraw)
      end,
    })
  end,
}
