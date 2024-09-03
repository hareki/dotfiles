return {
  "nvim-telescope/telescope.nvim",

  opts = {
    defaults = {
      layout_strategy = "vertical",
      layout_config = {
        vertical = {
          height = 0.9,
          preview_height = 0.5,
          preview_cutoff = 1,
          prompt_position = "bottom",
          width = 0.65,
        },
      },
    },
  },
}
