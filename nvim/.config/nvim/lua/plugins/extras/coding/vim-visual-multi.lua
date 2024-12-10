local find_under = "<C-n>"

return {
  {
    "mg979/vim-visual-multi",
    keys = {
      { find_under, mode = { "n", "x" } },
    },
    init = function()
      local wk = require("which-key")

      vim.g.VM_maps = {
        ["Find Under"] = find_under,
        ["Find Subword Under"] = find_under,
        ["Goto Next"] = "]v",
        ["Goto Prev"] = "[v",
      }

      local get_vm_icon = function()
        return vim.b.visual_multi == nil and {
          icon = "",
          color = "red",
        } or nil
      end

      wk.add({
        {
          "]v",
          icon = get_vm_icon,
          desc = "Cursor",
        },
        {
          "[v",
          icon = get_vm_icon,
          desc = "Cursor",
        },
      })
    end,
  },
}
