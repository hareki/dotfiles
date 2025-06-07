--  See `:help vim.keymap.set()`
local map = vim.keymap.set

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

map({ 'n', 'v' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll up and center' })
map({ 'n', 'v' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll down and center' })
map("x", "x", '"0d', { noremap = true, desc = "Cut to register 0" })
map("v", "<leader>t", "ygvgcp", { remap = true, silent = true, desc = "Yank, comment and paste" })

map('n', '<C-Left>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-Right>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-Down>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-Up>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
