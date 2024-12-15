-- Ditching it because cmdline completion doesn't work for some reason...
return {
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        return true
      end,
      completion = {
        menu = {
          border = "rounded",
          winhighlight = "Normal:CmpNormal,CursorLine:PmenuSel",
        },
        documentation = {
          window = {
            border = "rounded",
            winhighlight = "Normal:CmpNormal",
          },
        },
      },

      sources = {
        cmdline = function()
          LazyVim.notify("cmdline run")
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == "/" or type == "?" then
            return { "buffer" }
          end
          -- Commands
          if type == ":" then
            return { "cmdline" }
          end
          return {}
        end,
      },
    },
  },
}
