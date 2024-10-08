local quotes = {
  {
    "“Most people fail in life not because they aim too high and miss,",
    "but because they aim too low and hit.” — Les Brown",
  },
  {
    "“If you set your goals ridiculously high and it's a failure",
    "you will fail above everyone else's success.” — James Cameron",
  },
  {
    "“Never feel shame for trying and failing, for he who has never failed ",
    "is he who has never tried.” — Og Mandino",
  },
  { "“There is little success where there is little laughter.” — Andrew Carnegie" },
}

local function get_random_quote()
  local random_index = math.random(1, #quotes)
  local selected_quote = quotes[random_index]

  local footer = { "" }

  for _, line in ipairs(selected_quote) do
    table.insert(footer, line)
  end

  return footer
end

return {
  "nvimdev/dashboard-nvim",
  opts = function(_)
    local logo = [[
  ██╗  ██╗   █████╗   ██████╗   ███████╗  ██╗  ██╗  ██╗
  ██║  ██║  ██╔══██╗  ██╔══██╗  ██╔════╝  ██║ ██╔╝  ██║
  ███████║  ███████║  ██████╔╝  █████╗    █████╔╝   ██║
  ██╔══██║  ██╔══██║  ██╔══██╗  ██╔══╝    ██╔═██╗   ██║
  ██║  ██║  ██║  ██║  ██║  ██║  ███████╗  ██║  ██╗  ██║
  ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚══════╝  ╚═╝  ╚═╝  ╚═╝
    ]]
    logo = string.rep("\n", 4) .. logo .. "\n"

    return {
      theme = "hyper",
      config = {
        header = vim.split(logo, "\n"),
        center = {},
        project = { enable = true, limit = 2 },
        mru = { limit = 4 },
        -- footer = { "", '"Most people fail in life not because they aim too high and miss,', 'but because they aim too low and hit." — Les Brown' },
        footer = get_random_quote(),
        shortcut = {
          {
            icon = "󰊳 ",
            desc = "Sync",
            group = "@property",
            action = "Lazy sync",
            key = "s",
          },

          {
            icon = " ",
            desc = "Changelog",
            group = "@repeat",
            action = "Lazy log",
            key = "l",
          },
          {
            icon = "󰱼 ",
            desc = "Files",
            group = "DiagnosticHint",
            action = "Telescope find_files",
            key = "f",
          },
          {
            icon = "󰺯 ",
            desc = "Search",
            group = "Label",
            action = "Telescope live_grep",
            key = "g",
          },
          {
            icon = "󰈆 ",
            desc = "Exit",
            group = "@error",
            action = "exit",
            key = "e",
          },
        },
      },
    }
  end,
}
