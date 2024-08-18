return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  config = function()
    require("tiny-inline-diagnostic").setup({
      blend = {
        factor = 0.4,
      },
      options = {
        overflow = {
          mode = "oneline",
        },
        virt_texts = {
          priority = 1, --[[ smaller means higher priority ]]
        },
      },
    })
  end,
}
