local extensions = require("telescope").extensions
local telescope = require("telescope")

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

-- file/regular/normal buffers, whatever the name
local close_all_file_buffers = function()
  local bufs = vim.api.nvim_list_bufs()
  for _, bufnr in ipairs(bufs) do
    -- Check if the buffer is listed and has an empty 'buftype' (normal file buffer)
    if vim.fn.buflisted(bufnr) == 1 and vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "" then
      vim.api.nvim_buf_delete(bufnr, { force = false })
    end
  end
end

return {
  {
    "hareki/git-worktree.nvim",
    -- Waiting for this to be in the next version
    -- https://github.com/polarmutex/git-worktree.nvim/commit/604ab2dd763776a36d1aad9fd81a3c513c1d4d94
    version = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      local hooks = require("git-worktree.hooks")
      local which_key = require("which-key")
      telescope.load_extension("git_worktree")
      which_key.add({
        { "<leader>gw", group = "Git Worktree" },
      })

      hooks.register(hooks.type.SWITCH, function()
        refresh_neo_tree()
        refresh_lualine()
        close_all_file_buffers()
      end)

      -- Cant do these in "keys" since it would fail/throw error if git-worktree hasn't been installed yet
      Util.map("n", "<leader>gwl", "<cmd>Telescope git_worktree<cr>", { desc = "List" })
      Util.map("n", "<leader>gwc", extensions.git_worktree.create_git_worktree, { desc = "Create" })
    end,
  },
}
