return {
  "nvim-neo-tree/neo-tree.nvim",
  -- Prevent neotree from opening automatically
  -- init = function() end,
  opts = function(_, opts)
    opts.event_handlers = opts.event_handlers or {}
    -- Show relative line numbers for neo-tree
    -- source: https://stackoverflow.com/questions/77927924/add-relative-line-numbers-in-neo-tree-using-lazy-in-neovim
    table.insert(opts.event_handlers, {
      event = "neo_tree_buffer_enter",
      handler = function()
        vim.cmd([[
              setlocal relativenumber
            ]])
      end,
    })

    -- Auto Close on Open File
    -- table.insert(opts.event_handlers, {
    --   event = "file_open_requested",
    --   handler = function()
    --     require("neo-tree.command").execute({ action = "close" })
    --   end,
    -- })

    -- https://github.com/nvim-neo-tree/neo-tree.nvim/issues/533#issuecomment-1287950467
    Util.ensure_nested(opts, "window.popup").size = { height = "80%", width = "59%" }

    opts.popup_border_style = "rounded"
    opts.window.position = "float"

    opts.window.mappings["P"] = { "toggle_preview", config = { use_float = true } }

    opts.window.mappings["O"] = {
      function(state)
        local path = state.tree:get_node().path -- Absolute path of the node
        local cmd = "explorer.exe \"$(wslpath -w '" .. path .. "')\" >/dev/null 2>&1"
        os.execute(cmd)
        -- LazyVim.notify("Opened with explorer: " .. path)
        -- require("lazy.util").open(state.tree:get_node().path, { system = true })
      end,
      desc = "Open with System Application",
    }

    -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/370#discussioncomment-4144005
    opts.window.mappings["Y"] = function(state)
      -- NeoTree is based on [NuiTree](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree)
      -- The node is based on [NuiNode](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree#nuitreenode)
      local node = state.tree:get_node()
      local filepath = node:get_id()
      local filename = node.name
      local modify = vim.fn.fnamemodify

      local results = {
        modify(filepath, ":."),
        filename,
        filepath,
        modify(filepath, ":~"),
        modify(filename, ":r"),
        modify(filename, ":e"),
      }

      vim.ui.select({
        "1. Path relative to CWD: " .. results[1],
        "2. Filename: " .. results[2],
        "3. Absolute path: " .. results[3],
        "4. Path relative to HOME: " .. results[4],
        "5. Filename without extension: " .. results[5],
        "6. Extension of the filename: " .. results[6],
      }, { prompt = "Choose to copy to clipboard:" }, function(choice)
        if choice == nil then
          LazyVim.notify("Operation cancelled")
          return
        end
        local i = tonumber(choice:sub(1, 1))
        if i == nil then
          LazyVim.notify("Invalid choice", {
            level = vim.log.levels.ERROR,
          })
          return
        end
        local result = results[i]
        vim.fn.setreg("+", result)
        LazyVim.notify("Copied: " .. result)
      end)
    end

    opts.default_component_configs.indent.with_markers = false

    -- opts.source_selector = {
    --   winbar = true,
    --   statusline = true,
    -- }
  end,
}
