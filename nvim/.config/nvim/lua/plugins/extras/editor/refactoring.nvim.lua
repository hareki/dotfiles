return {
  {
    "ThePrimeagen/refactoring.nvim",
    keys = function()
      require("which-key").add({
        {
          "<leader>r",
          group = "Refactor",
          icon = "",
        },
      })
    end,
  },
}
