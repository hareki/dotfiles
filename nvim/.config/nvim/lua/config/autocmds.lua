-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local aucmd = Util.aucmd
local hl = Util.hl

local function disable_doc_hl()
  hl("LspReferenceRead", { bg = "none" })
  hl("LspReferenceText", { bg = "none" })
  hl("LspReferenceWrite", { bg = "none" })
end

local function enable_doc_hl()
  hl("LspReferenceRead", { link = "MyDocumentHighlight" })
  hl("LspReferenceText", { link = "MyDocumentHighlight" })
  hl("LspReferenceWrite", { link = "MyDocumentHighlight" })
end

-- NOTE: Disable autocomments
-- source: https://www.reddit.com/r/neovim/comments/13585hy/trying_to_disable_autocomments_on_new_line_eg/
aucmd("BufEnter", {
  pattern = "*",
  command = "set formatoptions-=cro",
})

aucmd("BufEnter", {
  pattern = "*",
  command = "setlocal formatoptions-=cro",
})

-- NOTE: Disable document highlight and pause vim-illuminate in visual mode
aucmd("ModeChanged", {
  pattern = "*:[vV\x16]*",
  callback = function()
    disable_doc_hl()
  end,
})

aucmd("ModeChanged", {
  pattern = "[vV\x16]*:*",
  callback = function()
    enable_doc_hl()
  end,
})

-- NOTE: Highlight all occurrences of selected text in visual mode
-- source: https://github.com/Losams/-VIM-Plugins/blob/master/checkSameTerm.vim

-- Global variable to track the state
vim.g.checkingSameTerm = 0

aucmd({ "CursorMoved", "ModeChanged" }, {
  pattern = "*",
  -- Function to check the same term
  callback = function()
    local currentmode = vim.api.nvim_get_mode().mode
    -- Check for (any) visual mode
    if currentmode == "v" or currentmode == "V" or currentmode == "\22" then
      vim.g.checkingSameTerm = 1
      -- Backing up what we're having in the register
      local s = vim.fn.getreg('"')

      -- Get currently selected text by yanking them into the register
      vim.cmd("silent! normal! ygv")
      local search_term = vim.fn.getreg('"')
      search_term = vim.fn.escape(search_term, "\\/"):gsub("\n", "\\n")
      -- Check if the search term is not just blank space or newline characters
      if search_term:match("^%s*$") == nil and search_term:match("^\\n*$") == nil then
        vim.cmd("match MyDocumentHighlight /\\V" .. search_term .. "/")
      else
        vim.cmd("match none")
      end

      -- Restore the text back to the register after searching
      vim.fn.setreg('"', s)
      vim.g.checkingSameTerm = 0
    else
      vim.cmd("match none")
    end
  end,
})

-- NOTE: Tweak the highlight_yank from LazyVim to have different colors based on the register name
-- source: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua#L17-L23
aucmd("TextYankPost", {
  group = Util.lazy_augroup("highlight_yank"),
  callback = function()
    -- Ensure yank-related events are processed first
    -- tiny-inline-diagnostic prevent the highlight on yank to work properly so we need to temporarily disable it during the highlight
    vim.defer_fn(function()
      -- require("tiny-inline-diagnostic").disable()
      disable_doc_hl()
    end, 50)

    local register = vim.v.event.regname
    if vim.g.checkingSameTerm == 0 then
      if register == "+" or register == "*" then
        vim.highlight.on_yank({ higroup = "YankSystemHighlight" })
      else
        vim.highlight.on_yank({ higroup = "YankRegisterHighlight" })
      end
    end
    -- vim.highlight.on_yank({ higroup = "YankRegisterHighlight" })

    -- Wait for the highlight to wear out before re-enabling it (default duration = 150ms, we wait for an extra 50ms just in case)
    vim.defer_fn(function()
      -- require("tiny-inline-diagnostic").enable()
      enable_doc_hl()
    end, Constant.yanky.PUT_HL_TIMER + 50)
  end,
})

-- Disable minipairs when entering search or command-line mode
aucmd("CmdlineEnter", {
  pattern = "[/:?]",
  callback = function()
    vim.g.minipairs_disable = true
  end,
})

aucmd("CmdlineLeave", {
  pattern = "[/:?]",
  callback = function()
    vim.g.minipairs_disable = false
  end,
})

-- https://www.reddit.com/r/neovim/comments/180tnhg/disable_miniindentscope_for_certain_filetypes/
aucmd("FileType", {
  desc = "Disable indentscope for certain filetypes",
  pattern = {
    "dropbar_menu",
  },
  callback = function()
    vim.b.miniindentscope_disable = true
  end,
})

aucmd("CmdlineLeave", {
  desc = "Center screen after jumping to a line number",
  callback = function()
    local cmd_type = vim.fn.getcmdtype()
    local cmd_line = vim.fn.getcmdline()

    if cmd_type == ":" then
      local line_number = tonumber(cmd_line)
      if line_number then
        vim.schedule(function()
          vim.cmd("normal! zz")
        end)
      end
    end
  end,
})
