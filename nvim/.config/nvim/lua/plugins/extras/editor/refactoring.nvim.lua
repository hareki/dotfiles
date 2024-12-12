return {
  {
    "ThePrimeagen/refactoring.nvim",
    keys = function()
      local wk = require("which-key")

      wk.add({
        {
          "<leader>r",
          group = "Refactor",
          icon = "",
        },
      })
    end,
  },
}
