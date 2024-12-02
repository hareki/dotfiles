return {
  {
    "smoka7/multicursors.nvim",
    dependencies = {
      "nvimtools/hydra.nvim",
    },
    opts = {
      hint_config = {
        float_opts = {
          border = "rounded",
        },
        position = "bottom",
      },
    },
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = function()
      local mc_start_key = "<leader>m"

      require("which-key").add({
        {
          mc_start_key,
          icon = "󰇀",
        },
      })

      return {
        {
          mode = { "v", "n" },
          mc_start_key,
          "<cmd>MCstart<cr>",
          desc = "Multicursors start",
        },
      }
    end,
  },
}
