-- A clone of map method from
-- https://github.com/folke/snacks.nvim/blob/bc0cf370915ac4e8d5b1bd8188b5091a4a0ee22c/lua/snacks/toggle.lua
-- Extend what can be toggled

-- local null_ls = require("null-ls")
local gitsigns = require("gitsigns")
local gitsigns_config = require("gitsigns.config").config

local get_typos_ns_id = function()
  local clients = vim.lsp.get_clients({ name = "typos_lsp" })
  local typos_lsp = clients[1]
  if not typos_lsp then
    return nil
  end
  return vim.lsp.diagnostic.get_namespace(typos_lsp.id)
end

---@class util.toggle
local M = {}

function M.typos_lsp()
  return Snacks.toggle.new({
    name = "typos-lsp",
    get = function()
      local ns_id = get_typos_ns_id()
      if not ns_id then
        -- LazyVim.warn("typos-lsp is not running")
        return false
      end

      return vim.diagnostic.is_enabled({ ns_id = ns_id })
    end,
    set = function(state)
      local ns_id = get_typos_ns_id()
      if not ns_id then
        -- LazyVim.warn("typos-lsp is not running")
        return
      end

      vim.diagnostic.enable(state, { ns_id = ns_id })
    end,
  })
end

function M.current_line_blame()
  return Snacks.toggle.new({
    name = "Current Line Blame",
    get = function()
      return gitsigns_config.current_line_blame
    end,
    set = function(state)
      gitsigns.toggle_current_line_blame(state)
    end,
  })
end

-- local cspell_query = { name = "cspell" }
-- local get_cspell_state = function()
--   return not null_ls.get_source(cspell_query)[1]._disabled
-- end
--
-- function M.cspell()
--   return Snacks.toggle.new({
--     name = "cspell",
--     get = function()
--       return get_cspell_state()
--     end,
--     set = function(state)
--       local cspell_state = get_cspell_state()
--       if state ~= cspell_state then
--         null_ls.toggle(cspell_query)
--       end
--     end,
--   })
-- end

return M
