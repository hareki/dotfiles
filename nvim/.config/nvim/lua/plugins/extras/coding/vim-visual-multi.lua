local find_under = "<C-n>"

return {
  {
    "mg979/vim-visual-multi",
    keys = {
      { find_under, mode = { "n", "x" } },
    },
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = find_under,
        ["Find Subword Under"] = find_under,
      }
    end,
  },
}
