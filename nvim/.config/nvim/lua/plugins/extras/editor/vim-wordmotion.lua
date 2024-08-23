return {
  "chaoren/vim-wordmotion",
  init = function()
    Util.map({ "n", "x", "o" }, "W", "w", { noremap = true })
    Util.map({ "o" }, "iW", "iw", { noremap = true })
    Util.map({ "n", "x", "o" }, "E", "e", { noremap = true })
    Util.map({ "n", "x", "o" }, "B", "b", { noremap = true })
  end
}
