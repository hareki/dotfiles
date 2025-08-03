return {
  'nvimdev/dashboard-nvim',
  enabled = false,
  lazy = false, -- As https://github.com/nvimdev/dashboard-nvim/pull/450, dashboard-nvim shouldn't be lazy-loaded to properly handle stdin.
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function()
    local logo = {
      [[                                                                       ]],
      [[                                                                     ]],
      [[       ████ ██████           █████      ██                     ]],
      [[      ███████████             █████                             ]],
      [[      █████████ ███████████████████ ███   ███████████   ]],
      [[     █████████  ███    █████████████ █████ ██████████████   ]],
      [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
      [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
      [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
      [[                                                                       ]],
    }

    local stats = require('lazy').stats()
    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)

    local version = vim.version()
    local formatted_version = string.format('%d.%d.%d', version.major, version.minor, version.patch)

    return {
      theme = 'hyper',
      shortcut_type = 'letter',
      letter_list = 'abcdefghijklmnopqrstuvwxyz', -- j and k are fine, I'm not using them

      hide = {
        statusline = true,
        tabline = true,
        winbar = true,
      },
      config = {
        header = logo,
        packages = {
          enable = false,
        },
        shortcut = {
          {
            desc = ' ' .. stats.loaded .. '/' .. stats.count .. ' plugins',
          },
          {
            desc = '󱎫 ' .. ms .. ' ms',
          },
        },
      },
    }
  end,
}

-- dashboard.section.footer.val = ' '
--   .. stats.loaded
--   .. '/'
--   .. stats.count
--   .. ' plugins  󱎫 '
--   .. ms
--   .. ' ms   v'
--   .. formatted_version
