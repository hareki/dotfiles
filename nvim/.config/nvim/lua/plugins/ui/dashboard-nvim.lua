return {
  require('utils.ui').catppuccin(function(palette)
    return {
      DashboardHeader = { fg = palette.blue },
      DashboardShortcut = { fg = palette.yellow },
      DashboardShortcut1 = { fg = palette.pink },
      DashboardShortcut2 = { fg = palette.yellow },
      DashboardShortcut3 = { fg = palette.green },
      DashboardShortcut4 = { fg = palette.mauve },
      DashboardShortcut5 = { fg = palette.red },
      DashboardProjectTitle = { fg = palette.blue },
      DashboardProjectIcon = { fg = palette.blue },
      DashboardMruTitle = { fg = palette.blue },
      DashboardFiles = { fg = palette.text },
      DashboardFooter = { fg = palette.rosewater, italic = true },
    }
  end),
  {
    'hareki/dashboard-nvim',
    enabled = true,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- A complete copy pasta of
    -- https://github.com/nvimdev/dashboard-nvim/blob/0775e567b6c0be96d01a61795f7b64c1758262f6/plugin/dashboard.lua#L5
    -- Normally we would just do lazy = false and let the code from the link above do it
    -- But that will cause nvim-web-devicons to be unnecessarily loaded during startup
    init = function()
      local g = vim.api.nvim_create_augroup('dashboard', { clear = true })

      vim.api.nvim_create_autocmd('VimEnter', {
        group = g,
        callback = function()
          for _, v in pairs(vim.v.argv) do
            if v == '-' then
              vim.g.read_from_stdin = 1
              break
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd('UIEnter', {
        group = g,
        callback = function()
          if
            vim.fn.argc() == 0
            and vim.api.nvim_buf_get_name(0) == ''
            and vim.g.read_from_stdin == nil
          then
            require('dashboard'):instance()
          end
        end,
      })
    end,
    opts = function()
      -- math.random in Lua is deterministic until you seed it yourself.
      math.randomseed(vim.uv.hrtime())
      math.random() -- Discard the first LCG output, it's quite repeatable.

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
      local zen_quotes = {
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
        { "“Don't blame others. it won't make you a better person.”" },
      }

      local random_index = math.random(1, #zen_quotes)
      local random_quote = zen_quotes[random_index]

      vim.api.nvim_create_autocmd('User', {
        pattern = 'DashboardLoaded',
        callback = function(ev)
          local buf = ev.data.buf
          local map = vim.keymap.set

          map({ 'n', 'v' }, '<PageUp>', '<C-u>', { desc = 'Scroll Up', buffer = buf })
          map({ 'n', 'v' }, '<PageDown>', '<C-d>', { desc = 'Scroll Down', buffer = buf })
        end,
      })

      local icons = require('configs.icons')

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
            item_icon = icons.kinds.Folder,
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
  },
}
