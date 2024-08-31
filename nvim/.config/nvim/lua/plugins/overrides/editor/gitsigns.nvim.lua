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

    local orig_on_attach = opts.on_attach
    opts.on_attach = function(buffer)
      orig_on_attach(buffer)

      local function gs_map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      local function gs_unmap(mode, l)
        vim.keymap.del(mode, l, { buffer = buffer })
      end

      -- By default LazyVim uses preview_hunk_inline
      gs_unmap("n", "<leader>ghp")
      gs_map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
    end
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
