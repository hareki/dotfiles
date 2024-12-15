return {
  "chaoren/vim-wordmotion",
  init = function()
    local map = Util.map

    map({ "n", "x", "o" }, "W", "w")
    map({ "o" }, "iW", "iw")
    map({ "n", "x", "o" }, "E", "e")
    map({ "n", "x", "o" }, "B", "b")
  end,
}
