return {
  "nvimdev/dashboard-nvim",
  opts = function(_, opts)
    local logo = [[
   ██╗  ██╗  █████╗  ██████╗  ███████╗ ██╗  ██╗ ██╗
   ██║  ██║ ██╔══██╗ ██╔══██╗ ██╔════╝ ██║ ██╔╝ ██║
   ███████║ ███████║ ██████╔╝ █████╗   █████╔╝  ██║
   ██╔══██║ ██╔══██║ ██╔══██╗ ██╔══╝   ██╔═██╗  ██║
   ██║  ██║ ██║  ██║ ██║  ██║ ███████╗ ██║  ██╗ ██║
   ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝
    ]]
    logo = string.rep("\n", 6) .. logo .. "\n"
    opts.theme = "hyper"
    opts.config = {
      header = vim.split(logo, "\n"),
      center = {},
      shortcut = {
        { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
        {
          icon = ":u6709: ",
          icon_hl = "@variable",
          desc = "Files",
          group = "Label",
          action = "Telescope find_files",
          key = "f",
        },
        {
          desc = " Apps",
          group = "DiagnosticHint",
          action = "Telescope app",
          key = "a",
        },
        {
          desc = " dotfiles",
          group = "Number",
          action = "Telescope dotfiles",
          key = "d",
        },
      },
    }
  end,
}
