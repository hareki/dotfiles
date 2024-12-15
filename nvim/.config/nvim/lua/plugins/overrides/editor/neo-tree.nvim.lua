local current_position = "float"

return {
  "nvim-neo-tree/neo-tree.nvim",

  -- prevent neotree from opening automatically
  -- init = function() end,

  keys = function(_, keys)
    local wk = require("which-key")

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

    wk.add({
      { "<leader>ut", group = "Set Neo-tree position" },
    })

    return vim.list_extend(keys, {
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
        "<leader>e",
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
    })
  end,

  opts = function(_, opts)
    local palette = Util.get_palette()

    Util.highlights({
      NeoTreeNormal = { bg = palette.base },
      NeoTreeNormalNC = { bg = palette.base },
      -- NeoTreeWinSeparator = { bg = colors.mantle, fg = colors.mantle },
    })

    return vim.tbl_deep_extend("force", opts, {
      popup_border_style = "rounded",
      event_handlers = vim.list_extend(opts.event_handlers or {}, {
        -- Show relative line numbers for neo-tree
        -- https://stackoverflow.com/questions/77927924/add-relative-line-numbers-in-neo-tree-using-lazy-in-neovim
        {
          event = "neo_tree_buffer_enter",
          handler = function()
            vim.cmd([[
              setlocal relativenumber
            ]])
          end,
        },

        -- Auto Close on Open File
        -- {
        --   event = "file_open_requested",
        --   handler = function()
        --     require("neo-tree.command").execute({ action = "close" })
        --   end,
        -- }
      }),
      default_component_configs = {
        indent = {
          with_markers = false,
        },
        icon = {
          folder_closed = "",
          folder_open = "",
          folder_empty = "",
        },
      },

      window = {
        position = current_position,
        popup = {
          size = {
            -- https://github.com/nvim-neo-tree/neo-tree.nvim/issues/533#issuecomment-1287950467
            height = "80%",
            width = "50%",
          },
        },

        mappings = {
          P = { "toggle_preview", config = { use_float = true } },
          Z = "expand_all_nodes",
          O = {
            function(state)
              local path = state.tree:get_node().path -- Absolute path of the node
              local cmd = "explorer.exe \"$(wslpath -w '" .. path .. "')\" >/dev/null 2>&1"
              os.execute(cmd)
              -- LazyVim.notify("Opened with explorer: " .. path)
              -- require("lazy.util").open(state.tree:get_node().path, { system = true })
            end,
            desc = "Open with system application",
          },

          -- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/370#discussioncomment-4144005
          Y = function(state)
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
          end,
        },
      },
    })
  end,
}
