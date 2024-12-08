local current_position = "float"

return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = function(_, keys)
    local wk = require("which-key")
    wk.add({
      { "<leader>ut", group = "Set Neo-tree position" },
    })

    -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/826#discussioncomment-5431757
    local function is_open()
      local manager = require("neo-tree.sources.manager")
      local renderer = require("neo-tree.ui.renderer")

      local state = manager.get_state("filesystem")
      local window_exists = renderer.window_exists(state)
      return window_exists
    end

    local function set_position(position)
      current_position = position
      if is_open() then
        require("neo-tree.command").execute({
          reveal = true,
          position = current_position,
        })
      end
      LazyVim.notify("Neo-tree position set to " .. position)
    end

    local mappings = {
      {
        "<leader>utf",
        function()
          set_position("float")
        end,
        desc = "Set Neo-tree position to float",
      },
      {
        "<leader>utl",
        function()
          set_position("left")
        end,
        desc = "Set Neo-tree position to left",
      },
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            reveal = true,
            position = current_position,
            dir = LazyVim.root(),
          })
        end,
        desc = "Explorer Neo-tree (root dir)",
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            reveal = true,
            position = current_position,
            dir = vim.uv.cwd(),
          })
        end,
        desc = "Explorer Neo-tree (current dir)",
      },
    }

    return vim.list_extend(keys, mappings)
  end,
  -- init = function() end, -- prevent neotree from opening automatically
  opts = function(_, opts)
    opts.event_handlers = opts.event_handlers or {}
    -- Show relative line numbers for neo-tree
    -- https://stackoverflow.com/questions/77927924/add-relative-line-numbers-in-neo-tree-using-lazy-in-neovim
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
    Util.ensure_nested(opts, "window.popup").size = {
      height = "80%",
      width = "50%",
    }

    opts.popup_border_style = "rounded"
    opts.window.position = current_position

    local icon = Util.ensure_nested(opts, "default_component_configs.icon")
    icon.folder_closed = ""
    icon.folder_open = ""
    icon.folder_empty = ""

    local win_mappings = opts.window.mappings
    win_mappings["P"] = { "toggle_preview", config = { use_float = true } }
    win_mappings["Z"] = "expand_all_nodes"

    win_mappings["O"] = {
      function(state)
        local path = state.tree:get_node().path -- Absolute path of the node
        local cmd = "explorer.exe \"$(wslpath -w '" .. path .. "')\" >/dev/null 2>&1"
        os.execute(cmd)
        -- LazyVim.notify("Opened with explorer: " .. path)
        -- require("lazy.util").open(state.tree:get_node().path, { system = true })
      end,
      desc = "Open with system application",
    }

    -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/370#discussioncomment-4144005
    win_mappings["Y"] = function(state)
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
  end,
}
