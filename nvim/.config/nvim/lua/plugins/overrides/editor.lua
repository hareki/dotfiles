local gitsigns = require("gitsigns")
local gitsigns_config = require("gitsigns.config").config

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      {
        "adelarsq/image_preview.nvim",
        event = "VeryLazy",
        config = function()
          require("image_preview").setup()
        end,
      },
    },
    opts = function(_, opts)
      -- Show relative line numbers for neo-tree
      -- source: https://stackoverflow.com/questions/77927924/add-relative-line-numbers-in-neo-tree-using-lazy-in-neovim
      opts.event_handlers = opts.event_handlers or {}
      table.insert(opts.event_handlers, {
        event = "neo_tree_buffer_enter",
        handler = function()
          vim.cmd([[
              setlocal relativenumber
            ]])
        end,
      })

      opts.commands = opts.commands or {}
      opts.commands = vim.tbl_extend("force", opts.commands, {
        image_wezterm = function(state)
          local node = state.tree:get_node()
          if node.type == "file" then
            require("image_preview").PreviewImage(node.path)
          end
        end,
      })

      local filesystem_mappings = Util.ensure_nested_table.run(opts, "filesystem", "window", "mappings")
      filesystem_mappings["<leader>p"] = "image_wezterm"

      opts.window.mappings["P"] = { "toggle_preview", config = { use_float = true } }

      opts.default_component_configs.indent.with_markers = false
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
      opts.current_line_blame = true
      opts.current_line_blame_formatter = "      <author>, <author_time:%R> - <summary>"
      opts.current_line_blame_opts = {
        delay = 500,
      }

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
  },
}
