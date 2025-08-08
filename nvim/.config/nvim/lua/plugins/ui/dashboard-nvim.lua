-- math.random in Lua is deterministic until you seed it yourself.
math.randomseed(vim.loop.hrtime())
math.random() -- Discard the first linear-congruential generator (LCG) output, it's quite repeatable.

return {
  'hareki/dashboard-nvim',
  enabled = true,
  lazy = false, -- As https://github.com/nvimdev/dashboard-nvim/pull/450, dashboard-nvim shouldn't be lazy-loaded to properly handle stdin.
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function()
    local logo = {
      [[                                                                    ]],
      [[      ████ ██████           █████      ██                     ]],
      [[     ███████████             █████                             ]],
      [[     █████████ ███████████████████ ███   ███████████   ]],
      [[    █████████  ███    █████████████ █████ ██████████████   ]],
      [[   █████████ ██████████ █████████ █████ █████ ████ █████   ]],
      [[ ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
      [[██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
      [[                                                                       ]],
    }

    -- https://zenquotes.io/
    local ambitious = {
      {
        'Most people fail in life not because they aim too high and miss,',
        'but because they aim too low and hit.',
      },
      {
        "If you set your goals ridiculously high and it's a failure",
        "you will fail above everyone else's success.",
      },
      {
        'Never feel shame for trying and failing, for he who has never failed ',
        'is he who has never tried.',
      },
      { 'There is little success where there is little laughter.' },
    }

    local random_index = math.random(1, #ambitious)
    -- Harcoding for now
    local random_quote = { "“Don't blame others. it won't make you a better person.”" }
      or ambitious[random_index]

    vim.api.nvim_create_autocmd('User', {
      pattern = 'DashboardLoaded',
      callback = function(ev)
        local buf = ev.data.buf
        local map = vim.keymap.set

        map({ 'n', 'v' }, '<PageUp>', '<C-u>', { desc = 'Scroll up', buffer = buf })
        map({ 'n', 'v' }, '<PageDown>', '<C-d>', { desc = 'Scroll down', buffer = buf })
      end,
    })

    return {
      theme = 'hyper',
      shortcut_type = 'letter',
      letter_list = 'abcdefghijklmnopqrstuvwxyz', -- j and k are fine, I'm not using them
      change_to_vcs_root = true,

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
        project = {
          enable = true,
          limit = 4,
          icon = '󰪺 ',
          item_icon = '󰉋 ',
          label = ' Projects',
        },
        shortcut = function()
          local stats = require('lazy').stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          local version = vim.version()
          local formatted_version =
            string.format('%d.%d.%d', version.major, version.minor, version.patch)

          return {
            {
              icon = ' ',
              desc = stats.loaded .. '/' .. stats.count .. ' plugins',
              group = 'DashboardShortcut1',
            },
            {
              icon = '󱎫 ',
              desc = ms .. ' ms',
              group = 'DashboardShortcut2',
            },
            {
              icon = ' ',
              desc = 'v' .. formatted_version,
              group = 'DashboardShortcut3',
            },
            {
              -- TODO: Implement session restore
              -- action = 'lua require("persistence").load()',
              action = 'lua print("Restore Session")',
              desc = ' Restore',
              icon = '󱍷',
              key = 'r',
              group = 'DashboardShortcut4',
            },
            {
              action = 'lua vim.cmd("qa!")',
              desc = ' Quit',
              icon = '󰅗',
              key = 'q',
              group = 'DashboardShortcut5',
            },
          }
        end,
        mru = { enable = true, limit = 4, icon = '󱋡 ', label = ' Files' },
        footer = vim.list_extend({ '' }, random_quote),
      },
    }
  end,
}
