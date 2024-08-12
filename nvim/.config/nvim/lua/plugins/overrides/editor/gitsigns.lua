local gitsigns = require("gitsigns")
local gitsigns_config = require("gitsigns.config").config

return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    opts.current_line_blame = true
    -- opts.current_line_blame_formatter = "      <author>, <author_time:%R> - <summary>"
    opts.current_line_blame_formatter = "<author>, <author_time:%R> - <summary>"

    local blame_opts = Util.ensure_nested_table.run(opts, "current_line_blame_opts")

    blame_opts.delay = 300
    -- blame_opts.virt_text_priority = 999
    blame_opts.virt_text = true

    opts.preview_config = {
      border = "rounded",
    }
  end,
  keys = {
    {
      "<leader>ub",
      function()
        local next_blame_value = not gitsigns_config.current_line_blame
        local notify = next_blame_value and LazyVim.info or LazyVim.warn

        notify(Util.toggle_notify.run("current line blame", next_blame_value), { title = "gitsigns" })
        gitsigns.toggle_current_line_blame()
      end,
      desc = "Toggle current line blame",
    },
  },
}
