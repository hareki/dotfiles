-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- NOTE: Disable autocomments
-- source: https://www.reddit.com/r/neovim/comments/13585hy/trying_to_disable_autocomments_on_new_line_eg/
Util.aucmd("BufEnter", {
  pattern = "*",
  command = "set formatoptions-=cro",
})

Util.aucmd("BufEnter", {
  pattern = "*",
  command = "setlocal formatoptions-=cro",
})

-- NOTE: Disable document highlight in visual mode
Util.aucmd("ModeChanged", {
  pattern = "*:[vV\x16]*",
  callback = function()
    vim.cmd("highlight LspReferenceRead guibg=none")
    vim.cmd("highlight LspReferenceText guibg=none")
    vim.cmd("highlight LspReferenceWrite guibg=none")
  end,
})

Util.aucmd("ModeChanged", {
  pattern = "[vV\x16]*:*",
  callback = function()
    vim.cmd("highlight! link LspReferenceRead MyDocumentHighlight")
    vim.cmd("highlight! link LspReferenceText MyDocumentHighlight")
    vim.cmd("highlight! link LspReferenceWrite MyDocumentHighlight")
  end,
})

-- NOTE: Highlight all occurrences of selected text in visual mode
-- source: https://github.com/Losams/-VIM-Plugins/blob/master/checkSameTerm.vim

-- Global variable to track the state
vim.g.checkingSameTerm = 0

Util.aucmd({ "CursorMoved", "ModeChanged" }, {
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
Util.aucmd("TextYankPost", {
  group = Util.lazy_augroup("highlight_yank"),
  callback = function()
    local register = vim.v.event.regname
    if vim.g.checkingSameTerm == 0 then
      if register == "+" or register == "*" then
        vim.highlight.on_yank({ higroup = "YankHighlightSystem" })
      else
        vim.highlight.on_yank()
      end
    end
  end,
})
