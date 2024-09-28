return {
  {
    "ThePrimeagen/git-worktree.nvim",
    init = function()
      require("telescope").load_extension("git_worktree")
    end,
  },
}
