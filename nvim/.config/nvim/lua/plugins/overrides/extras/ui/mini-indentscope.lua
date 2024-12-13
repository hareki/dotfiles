return {
  {
    "echasnovski/mini.indentscope",
    init = function()
      -- https://www.reddit.com/r/neovim/comments/180tnhg/disable_miniindentscope_for_certain_filetypes/
      Util.aucmd("FileType", {
        desc = "Disable indentscope for certain filetypes",
        pattern = {
          "dropbar_menu",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,

    opts = {
      draw = {
        delay = 0,
        animation = require("mini.indentscope").gen_animation.none(),
      },
    },
  },
}
