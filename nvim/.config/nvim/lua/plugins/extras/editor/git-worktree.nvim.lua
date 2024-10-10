local extensions = require("telescope").extensions

return {
  {
    "hareki/git-worktree.nvim",
    -- Waiting for this to be in the next version
    -- https://github.com/polarmutex/git-worktree.nvim/commit/604ab2dd763776a36d1aad9fd81a3c513c1d4d94
    version = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      require("telescope").load_extension("git_worktree")

      require("which-key").add({
        { "<leader>gw", group = "Git Worktree" },
      })
    end,
    keys = {
      { "<leader>gwl", "<cmd>Telescope git_worktree<cr>", desc = "List" },
      -- NOTE: Would fail/throw error if git-worktree hasn't been installed yet
      { "<leader>gwc", extensions.git_worktree.create_git_worktree, desc = "Create" },
    },
  },
}
