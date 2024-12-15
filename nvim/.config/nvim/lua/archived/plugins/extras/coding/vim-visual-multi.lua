local find_under = "<C-n>"

return {
  {
    "mg979/vim-visual-multi",
    keys = {
      { find_under, mode = { "n", "x" } },
    },
    config = function()
      local g = vim.g
      local wk = require("which-key")
      local colors = Util.get_palette()

      local get_vm_icon = function()
        return vim.b.visual_multi == nil and {
          icon = "",
          color = "red",
        } or nil
      end

      Util.highlights({
        -- https://github.com/mg979/vim-visual-multi/blob/master/doc/vm-settings.txt
        VM_Extend = { link = "Visual" },
        VM_Cursor = { bg = colors.rosewater, fg = colors.base },
        VM_Mono = { link = "VM_Cursor" },
        VM_Highlight_Matches = { link = "DocumentHighlight" }, -- This is not official, just to unify the naming convention
      })

      -- https://github.com/mg979/vim-visual-multi/blob/a6975e7c1ee157615bbc80fc25e4392f71c344d4/doc/vm-settings.txt#L21
      g.VM_highlight_matches = "hi! link Search VM_Highlight_Matches"
      g.VM_maps = {
        ["Find Under"] = find_under,
        ["Find Subword Under"] = find_under,
        ["Goto Next"] = "]v",
        ["Goto Prev"] = "[v",
      }

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
