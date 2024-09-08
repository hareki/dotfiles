-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- local gitsigns = require("gitsigns")
--
-- local gitsigns_config = require("gitsigns.config").config
--
-- -- require("extras.which-key-info-overrides").setup()
-- Util.toggle({
--   feature = "current line blame",
--   title = "gitsigns",
--   toggle_func = gitsigns.toggle_current_line_blame,
--   value = gitsigns_config.current_line_blame,
--   lhs = "<leader>ub",
-- })

-- NOTE: these are just general keymaps, there are other keymaps that closely related to some plugin so they're not here
-- We can find them with the "keys = " or "Util.map" keywords
Util.map("i", "jk", "<Esc>", { noremap = true, desc = "Map jk to Esc in insert mode" })

Util.map({ "i", "x", "n", "s" }, "<C-a>", "<cmd>wa<cr><esc>", { desc = "Save File", silent = true })

Util.map({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
Util.map({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })

-- NOTE: use yanky.nvim instead
-- Util.map("x", "p", '"_dP', { noremap = true, desc = "Paste without overwriting register" })
-- Util.map({ "n", "x" }, "P", '"0p', { noremap = true, desc = "Paste from last yank register" })

Util.map("x", "x", '"0d', { noremap = true, desc = "Cut to register 0" })

-- wezterm.action.PasteFrom is set to <C-v> in .wezterm.lua
Util.map({ "x" }, "<C-c>", '"+y', { desc = "Yank to system clipboard", noremap = true })

Util.map("v", "<leader>t", "ygvgcp", { remap = true, silent = true, desc = "Yank, comment and paste" })
Util.map("n", "<A-v>", "<C-v>", { silent = true, desc = "Visual Block Mode" })

-- for my muscle memory (always press shift when split window)
Util.unmap("n", "<leader>-")
Util.map("n", "<leader>_", "<C-W>s", { desc = "Split Window Below", remap = true })

-- Use wezterm.action.PasteFrom instead due to issues related to SSH: https://github.com/wez/wezterm/issues/2050
-- Util.map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
-- Util.map({ "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })

-- Util.map(
--   { "n" },
--   "<leader>cw",
--   "<cmd>:%s/\\r//g<cr><esc>",
--   { desc = "Remove <C-M> end of line character on [W]indows", silent = true }
-- )
