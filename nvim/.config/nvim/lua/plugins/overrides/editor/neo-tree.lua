return {
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

    -- opts.source_selector = {
    --   winbar = true,
    --   statusline = true,
    -- }
  end,
}
