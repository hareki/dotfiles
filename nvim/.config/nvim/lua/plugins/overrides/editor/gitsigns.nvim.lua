return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    local gitsigns = require("gitsigns")
    local orig_on_attach = opts.on_attach

    return vim.tbl_deep_extend("force", opts, {
      current_line_blame = true,
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      current_line_blame_opts = {
        delay = 300,
        virt_text = true,
        virt_text_priority = 999,
      },

      preview_config = {
        border = "rounded",
      },

      on_attach = function(buffer)
        orig_on_attach(buffer)

        local function gs_map(mode, l, r, desc)
          Util.map(mode, l, r, { buffer = buffer, desc = desc })
        end

        local function gs_unmap(mode, l)
          Util.unmap(mode, l, { buffer = buffer })
        end

        gs_unmap("n", "<leader>ghp")
        gs_map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
      end,
    })
  end,
}
