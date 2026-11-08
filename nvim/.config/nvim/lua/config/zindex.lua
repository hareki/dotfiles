--- Stacking order of this config's floats, lowest first; Neovim's own floats default to 50
--- @class config.zindex
local M = {}

-- Zen: over satellite.nvim's scrollbars (40) in a normal window, under the Snacks floats
M.ZEN = 50
-- nvim-tree's preview: the plugin default puts vim.ui.input behind it
M.TREE_PREVIEW = 50
-- Snacks floats (pickers, Snacks.win styles.float): over satellite.nvim's bars (51) and zen
M.FLOAT = 52
-- Full-screen panels and the terminal: over pickers and nvim-tree, which only stack over floats
-- below 100
M.PANEL = 100
-- Notifications: above the panels; an equal zindex hides one behind a focused panel
M.NOTIFY = 101
-- Trouble's preview float
M.TROUBLE_PREVIEW = 200
-- noice's cmdline popup, above everything
M.CMDLINE = 999

return M
