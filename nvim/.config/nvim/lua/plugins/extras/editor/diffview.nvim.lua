return {
  {
    "sindrets/diffview.nvim",
    cmd = "DiffviewOpen",
    init = function()
      local map = Util.map
      local wk = require("which-key")
      local git = Util.git

      wk.add({
        { "<leader>gd", group = "Diff", icon = {
          icon = "",
          color = "green",
        } },
      })

      map("n", "<leader>gdl", function()
        local current_commit = git.get_current_line_commit()
        if not current_commit then
          LazyVim.warn("No commit history for this line")
          return
        end

        git.diff_parent(current_commit)
      end, { desc = "current line's commit" })

      map("n", "<leader>gdt", git.diff_parent, { desc = "current" })
    end,
  },
}
