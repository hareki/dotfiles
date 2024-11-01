return {
  {
    "ThePrimeagen/refactoring.nvim",
    keys = function(_, keys)
      require("which-key").add({
        {
          "<leader>r",
          group = "Refactor",
          icon = "",
        },
      })

      return keys
    end,
  },
}
