--  See `:help vim.keymap.set()`
local map = vim.keymap.set

map({ "n", "x" }, "<A-c>", '"+y', { desc = "Yank to system clipboard", remap = true })
map({ "n", "x" }, "<A-x>", '"+d', { desc = "Cut to system clipboard", remap = true })
map({ "n", "x" }, "<A-v>", '"+p', { desc = "Paste from system clipboard", remap = true })
map({ "i" }, "<A-v>", '<C-o>"+p', { desc = "Paste from system clipboard", remap = true })

map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

map({ 'n', 'v' }, '<PageUp>', '<C-u>zz', { desc = 'Scroll up and center' })
map({ 'n', 'v' }, '<PageDown>', '<C-d>zz', { desc = 'Scroll down and center' })
map("x", "x", '"0d', { desc = "Cut to register 0" })
map("v", "<leader>t", "ygvgcp", { remap = true, silent = true, desc = "Yank, comment and paste" })

map('n', '<C-Left>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
map('n', '<C-Right>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
map('n', '<C-Down>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
map('n', '<C-Up>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better up/down
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>\\", "<C-W>v", { desc = "Split Window Right", remap = true })
