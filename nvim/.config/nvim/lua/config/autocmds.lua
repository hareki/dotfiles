-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/hareki/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local aucmd = Util.aucmd
local hl = Util.hl

local function disable_doc_hl()
  hl("LspReferenceRead", { bg = "none" })
  hl("LspReferenceText", { bg = "none" })
  hl("LspReferenceWrite", { bg = "none" })
end

local function enable_doc_hl()
  hl("LspReferenceRead", { link = "DocumentHighlight" })
  hl("LspReferenceText", { link = "DocumentHighlight" })
  hl("LspReferenceWrite", { link = "DocumentHighlight" })
end

-- Disable LSP reference highlight in visual mode and vim-visual-multi
-- vim-visual-multi makes normal and visual mode switch back and forth multiple times,
-- so we only run the enable/disable_doc_hl for visual mode change if vim-visual-multi isn't active
aucmd("ModeChanged", {
  pattern = "*:[vV\x16]*",
  callback = function()
    if vim.b.visual_multi == nil then
      disable_doc_hl()
    end
  end,
})

aucmd("User", {
  pattern = "visual_multi_start",
  callback = function()
    disable_doc_hl()
  end,
})

aucmd("ModeChanged", {
  pattern = "[vV\x16]*:*",
  callback = function()
    if vim.b.visual_multi == nil then
      enable_doc_hl()
    end
  end,
})

aucmd("User", {
  pattern = "visual_multi_exit",
  callback = function()
    enable_doc_hl()
  end,
})

-- Disable autocomments
-- https://www.reddit.com/r/neovim/comments/13585hy/trying_to_disable_autocomments_on_new_line_eg/
aucmd("BufEnter", {
  pattern = "*",
  command = "set formatoptions-=cro",
})

aucmd("BufEnter", {
  pattern = "*",
  command = "setlocal formatoptions-=cro",
})

-- Highlight all occurrences of selected text in visual mode
-- https://github.com/Losams/-VIM-Plugins/blob/master/checkSameTerm.vim
vim.g.checking_same_term = 0
aucmd({ "CursorMoved", "ModeChanged" }, {
  pattern = "*",
  -- Function to check the same term
  callback = function()
    local currentmode = vim.api.nvim_get_mode().mode
    -- Check for (any) visual mode
    if currentmode == "v" or currentmode == "V" or currentmode == "\22" then
      vim.g.checking_same_term = 1
      -- Backing up what we're having in the register
      local s = vim.fn.getreg('"')

      -- Get currently selected text by yanking them into the register
      vim.cmd("silent! normal! ygv")
      local search_term = vim.fn.getreg('"')
      search_term = vim.fn.escape(search_term, "\\/"):gsub("\n", "\\n")
      -- Check if the search term is not just blank space or newline characters
      if search_term:match("^%s*$") == nil and search_term:match("^\\n*$") == nil then
        vim.cmd("match DocumentHighlight /\\V" .. search_term .. "/")
      else
        vim.cmd("match none")
      end

      -- Restore the text back to the register after searching
      vim.fn.setreg('"', s)
      vim.g.checking_same_term = 0
    else
      vim.cmd("match none")
    end
  end,
})

-- Tweak the highlight_yank from LazyVim to have different colors based on the register name
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua#L17-L23
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
    if vim.g.checking_same_term == 0 then
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
      if vim.b.visual_multi == nil then
        enable_doc_hl()
      end
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
