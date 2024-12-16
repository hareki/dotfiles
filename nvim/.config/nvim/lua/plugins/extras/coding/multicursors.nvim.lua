return {
  {
    "hareki/multicursors.nvim",
    dependencies = {
      {
        "nvimtools/hydra.nvim",
        opts = function()
          local palette = Util.get_palette()

          Util.highlights({
            HydraRed = { fg = palette.peach },
            HydraAmaranth = { fg = palette.red },
            HydraBlue = { fg = palette.blue },
            HydraTeal = { fg = palette.teal },
            HydraPink = { fg = palette.pink },
          })
        end,
      },
    },
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        mode = { "v", "n" },
        "<Leader>m",
        "<cmd>MCstart<cr>",
        desc = "Multicursors start",
      },
    },

    opts = function(_, opts)
      local palette = Util.get_palette()
      local I = require("multicursors.insert_mode")

      Util.highlights({
        MultiCursor = { link = "DocumentHighlight" },
        MultiCursorMain = { link = "DocumentHighlight" },
      })

      return vim.tbl_deep_extend("force", opts, {
        insert_keys = {
          ["<Esc"] = { method = false, opts = { desc = "exit" } },
        },
        hint_config = {
          float_opts = {
            width = 9999,
            border = "rounded",
            padding = { 1, 6 },
          },
        },
      })
    end,
  },
}
