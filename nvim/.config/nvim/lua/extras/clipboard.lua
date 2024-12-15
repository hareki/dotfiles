return {
  setup = function()
    local g = vim.g
    local osc52 = require("vim.ui.clipboard.osc52")
    -- https://github.com/neovim/neovim/discussions/28010#discussioncomment-9877494
    local function paste()
      return {
        vim.fn.split(vim.fn.getreg(""), "\n"),
        vim.fn.getregtype(""),
      }
    end

    g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
    }
  end,
}
