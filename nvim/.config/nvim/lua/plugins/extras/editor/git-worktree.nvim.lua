return {
  {
    "hareki/git-worktree.nvim",
    version = false,
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    cmd = { "Telescope git_worktree" },
    keys = {
      { "<leader>gwl", "<cmd>Telescope git_worktree<cr>", desc = "List" },
      {
        "<leader>gwc",
        function()
          local telescope = require("telescope")
          local extensions = telescope.extensions

          extensions.git_worktree.create_git_worktree()
        end,
        desc = "Create",
      },
    },
    config = function()
      local hooks = require("git-worktree.hooks")
      local which_key = require("which-key")

      vim.g.git_worktree = {
        prefill_upstream = true,
        auto_set_upstream = true,
      }

      which_key.add({
        { "<leader>gw", group = "Git Worktree" },
      })

      hooks.register(hooks.type.SWITCH, function()
        local refresh_neo_tree = function()
          local manager = require("neo-tree.sources.manager")
          local renderer = require("neo-tree.ui.renderer")
          local state = manager.get_state("filesystem")
          local window_exists = renderer.window_exists(state)
          if state and window_exists then
            require("neo-tree.sources.manager").navigate(state, Util.cwd())
          end
        end

        local refresh_lualine = function()
          require("lualine.components.branch.git_branch").find_git_dir()
          require("lualine").refresh()
        end

        refresh_neo_tree()
        refresh_lualine()
        Snacks.bufdelete.other()
      end)
    end,
  },
}
