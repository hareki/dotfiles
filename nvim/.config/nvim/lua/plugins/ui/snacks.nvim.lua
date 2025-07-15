return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 100, -- The docs recommend loading this plugin early
  opts = function()
    local float_config = Util.size.popup_config('input')

    return {
      words = {
        enabled = true,
      },
      input = {
        enabled = true,
      },
      styles = {
        input = {
          height = float_config.height,
          width = float_config.width,
          col = float_config.col,
          row = float_config.row,
        },
      },
    }
  end,
}
