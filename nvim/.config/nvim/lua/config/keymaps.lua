-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- NOTE: these are just general keymaps, there are other keymaps that closely related to some plugin so they're not here
-- We can find them with the "keys = " or "Util.map" keywords

require("which-key").add({
  -- lua/plugins/overrides/ui/lualine.nvim.lua
  { "<leader>ul", group = "Branch Format" },

  -- lua/plugins/overrides/editor/neo-tree.nvim.lua
  { "<leader>ut", group = "Set Neo-tree position" },
  {
    "<leader>r",
    group = "Refactor",
    icon = "",
  },
})

Util.toggle.map("<leader>ub", Util.toggle.current_line_blame)
Util.toggle.map("<leader>us", Util.toggle.typos_lsp)

Util.map("n", "U", function()
  vim.diagnostic.open_float(nil, { border = "rounded" })
end, { noremap = true, silent = true })

Util.map("i", "jk", "<Esc>", { noremap = true, desc = "Map jk to Esc in insert mode" })

Util.map({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
Util.map({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })

Util.map("x", "x", '"0d', { noremap = true, desc = "Cut to register 0" })

-- wezterm.action.PasteFrom is set to <C-v> in .wezterm.lua
Util.map({ "x" }, "<C-c>", '"+y', { desc = "Yank to system clipboard", noremap = true })

Util.map("v", "<leader>t", "ygvgcp", { remap = true, silent = true, desc = "Yank, comment and paste" })
Util.map("n", "<A-v>", "<C-v>", { silent = true, desc = "Visual Block Mode" })

Util.map("n", "<leader>_", "<C-W>s", { desc = "Split Window Below", remap = true })

-- Autoformat file on save asynchronously
local timer = false
Util.map({ "i", "x", "n", "s" }, "<C-s>", function()
  local start_time = timer and vim.loop.hrtime() or nil
  require("conform").format({ async = true }, function(_)
    vim.api.nvim_command("silent! write")

    if start_time then
      local end_time = vim.loop.hrtime()
      local elapsed_time_ms = (end_time - start_time) / 1e6
      print(string.format("Execution time: %.3f ms", elapsed_time_ms))
    end
  end)
end, { desc = "Save and async format file" })

Util.map("n", "<leader>bo", function()
  Util.buffer.close_file_buffers(false)
  LazyVim.notify("Deleted other buffers")
end, { desc = "Delete Other Buffers" })

-- Util.map("n", "<leader>t", function()
--   -- Add function to test here
--   LazyVim.notify("No test at the moment")
-- end, { desc = "Testing stuff", remap = true })

-- Use wezterm.action.PasteFrom instead due to issues related to SSH: https://github.com/wez/wezterm/issues/2050
-- Util.map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
-- Util.map({ "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
-- Util.map("n", "h", "x", { desc = "test124" })

-- Use yanky.nvim instead
-- Util.map("x", "p", '"_dP', { noremap = true, desc = "Paste without overwriting register" })
-- Util.map({ "n", "x" }, "P", '"0p', { noremap = true, desc = "Paste from last yank register" })
