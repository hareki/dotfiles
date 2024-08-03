-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

Util.map("i", "jk", "<Esc>", { noremap = true, desc = "Map jk to Esc in insert mode" })

Util.map(
  { "n" },
  "<leader>cw",
  "<cmd>:%s/\\r//g<cr><esc>",
  { desc = "Remove <C-M> end of line character on [W]indows", silent = true }
)

Util.map({ "n", "v" }, "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
Util.map({ "n", "v" }, "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })

Util.map("x", "p", '"_dP', { noremap = true, desc = "Paste without overwriting register" })
Util.map("x", "x", '"0d', { noremap = true, desc = "Cut to register 0" })
Util.map({ "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
Util.map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })
Util.map({ "n", "x" }, "P", '"0p', { noremap = true, desc = "Paste from last yank register" })

Util.map({ "i", "x", "n", "s" }, "<C-a>", "<cmd>wa<cr><esc>", { desc = "Save File", silent = true })
