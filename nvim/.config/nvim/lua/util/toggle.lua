-- NOTE:
-- A clone of map method from
-- https://github.com/LazyVim/LazyVim/blob/3dbace941ee935c89c73fd774267043d12f57fe2/lua/lazyvim/util/toggle.lua
-- Override keymap instead of skipping the already existing keymap. (vim.keymap.set instead of LazyVim.safe_keymap_set)
-- Extend what can be toggled

-- local null_ls = require("null-ls")
local gitsigns = require("gitsigns")
local gitsigns_config = require("gitsigns.config").config

---@class util.toggle
local M = {}

---@param lhs string
---@param toggle lazyvim.Toggle
function M.map(lhs, toggle)
  local t = LazyVim.toggle.wrap(toggle)
  Util.map("n", lhs, function()
    t()
  end, { desc = "Toggle " .. toggle.name })
  LazyVim.toggle.wk(lhs, toggle)
end

M.current_line_blame = LazyVim.toggle.wrap({
  name = "Current Line Blame",
  get = function()
    return gitsigns_config.current_line_blame
  end,
  set = function(state)
    gitsigns.toggle_current_line_blame(state)
  end,
})

-- local cspell_query = { name = "cspell" }
-- local get_cspell_state = function()
--   return not null_ls.get_source(cspell_query)[1]._disabled
-- end
--
-- M.cspell = LazyVim.toggle.wrap({
--   name = "cspell",
--   get = function()
--     return get_cspell_state()
--   end,
--   set = function(state)
--     local cspell_state = get_cspell_state()
--     if state ~= cspell_state then
--       null_ls.toggle(cspell_query)
--     end
--   end,
-- })

return M
