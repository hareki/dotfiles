return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    local gitsigns = require("gitsigns")

    opts.current_line_blame_opts = opts.current_line_blame_opts or {}

    opts.current_line_blame_opts.delay = 300
    opts.current_line_blame_opts.virt_text = true
    opts.current_line_blame_opts.virt_text_priority = 999

    opts.preview_config = {
      border = "rounded",
    }

    opts.current_line_blame = true
    opts.current_line_blame_formatter = "<author>, <author_time:%R> - <summary>"
    -- opts.current_line_blame_formatter = "      <author>, <author_time:%R> - <summary>"

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
      -- https://www.lazyvim.org/plugins/editor#gitsignsnvim
      gs_unmap("n", "<leader>ghp")
      gs_map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
    end
  end,
}
