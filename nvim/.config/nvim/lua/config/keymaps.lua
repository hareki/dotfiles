-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- NOTE: these are just general keymaps, there are other keymaps that closely related to some plugin so they're not here
-- We can find them with the "keys = " or "Util.map" keywords

Util.toggle.current_line_blame():map("<leader>ub")
Util.toggle.typos_lsp():map("<leader>us")

local map = Util.map

map("n", "U", function()
  vim.diagnostic.open_float(nil, { border = "rounded" })
end, { noremap = true, silent = true })

map("i", "jk", "<Esc>", { noremap = true, desc = "Map jk to Esc in insert mode" })

map("n", "<leader>uN", function()
  Snacks.notifier.show_history()
end, { noremap = true, desc = "Show notification history" })

map({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })

map("x", "x", '"0d', { noremap = true, desc = "Cut to register 0" })

-- wezterm.action.PasteFrom is set to <C-v> in .wezterm.lua
map({ "x" }, "<C-c>", '"+y', { desc = "Yank to system clipboard", noremap = true })
map({ "n", "x" }, "<C-y>", '"+y', { desc = "Yank to system clipboard", noremap = true })

map("v", "<leader>t", "ygvgcp", { remap = true, silent = true, desc = "Yank, comment and paste" })
map("n", "<A-v>", "<C-v>", { silent = true, desc = "Visual block mode" })

map("n", "<leader>_", "<C-W>s", { desc = "Split window below", remap = true })

-- Autoformat file on save asynchronously
local profile = false

---@diagnostic disable-next-line: undefined-field
local hrtime = vim.loop.hrtime

map({ "i", "x", "n", "s" }, "<C-s>", function()
  local start_time = profile and hrtime() or nil
  require("conform").format({ async = true }, function(_)
    vim.api.nvim_command("silent! write")

    if start_time then
      local end_time = hrtime()
      local elapsed_time_ms = (end_time - start_time) / 1e6
      print(string.format("Execution time: %.3f ms", elapsed_time_ms))
    end
  end)
end, { desc = "Save and async format file" })

map("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = LazyVim.root.git(), configure = false })
end, { desc = "Lazygit (root dir)" })

map("n", "<leader>gG", function()
  Snacks.lazygit({ configure = false })
end, { desc = "Lazygit (cwd)" })

-- Used testing stuff when needed
-- map("n", "<leader>t", function()
--   -- Add function to test here
--   LazyVim.notify("No test at the moment")
-- end, { desc = "Testing stuff", remap = true })

-- Use wezterm.action.PasteFrom instead due to issues related to SSH: https://github.com/wez/wezterm/issues/2050
-- map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

-- Use yanky.nvim instead
-- map("x", "p", '"_dP', { noremap = true, desc = "Paste without overwriting register" })
-- map({ "n", "x" }, "P", '"0p', { noremap = true, desc = "Paste from last yank register" })
