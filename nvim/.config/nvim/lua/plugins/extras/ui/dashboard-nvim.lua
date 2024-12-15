return {
  "nvimdev/dashboard-nvim",
  opts = function(_)
    local logo = [[                                                                      
                                                                         
          ████ ██████           █████      ██                     
         ███████████             █████                             
         █████████ ███████████████████ ███   ███████████   
        █████████  ███    █████████████ █████ ██████████████   
       █████████ ██████████ █████████ █████ █████ ████ █████   
     ███████████ ███    ███ █████████ █████ █████ ████ █████  
    ██████  █████████████████████ ████ █████ █████ ████ ██████ 
                                                                             ]]

    logo = string.rep("\n", 3) .. logo .. "\n"

    -- https://zenquotes.io/
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
      theme = "hyper",
      shuffle_letter = false,
      config = {
        header = vim.split(logo, "\n"),
        project = { enable = true, limit = 4 },
        mru = { enable = false, limit = 3 },
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
            icon = "   ",
            desc = "Changelog",
            group = "@repeat",
            action = "Lazy log",
            key = "l",
          },
          {
            icon = "  󰈆 ",
            desc = "Quit",
            group = "@error",
            action = "exit",
            key = "q",
          },
        },
      },
    }
  end,
}
