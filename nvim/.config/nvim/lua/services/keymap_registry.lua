---@class services.keymap_registry
local M = {}

M.desc_overrides = {
  ['[<leader>'] = { desc = 'Add Empty Line Above Cursor', mode = { 'n' } },
  [']<leader>'] = { desc = 'Add Empty Line Below Cursor', mode = { 'n' } },
  ['grn'] = { desc = 'LSP: Rename', mode = { 'n' } },
  ['grr'] = { desc = 'LSP: References', mode = { 'n' } },
  ['gO'] = { desc = 'LSP: Document Symbol', mode = { 'n' } },
  ['gri'] = { desc = 'LSP: Implementation', mode = { 'n' } },
  ['grt'] = { desc = 'LSP: Type Definition', mode = { 'n' } },
  ['gra'] = { desc = 'LSP: Code Actions', mode = { 'n', 'x' } },
  ['<C-S>'] = { desc = 'LSP: Signature Help', mode = { 's', 'i' } },
  ['K'] = { desc = 'LSP: Hover', mode = { 'n' } },
  ['gx'] = { desc = 'Open URL', mode = { 'n' } },
  -- ['<Tab>'] = { desc = 'Copilot: Accept Suggestion', mode = { 'i' } },
  -- ['<S-Tab>'] = { desc = 'Copilot: Accept Suggestion (Word)', mode = { 'i' } },
  -- ['<M-]>'] = { desc = 'Copilot: Next Suggestion', mode = { 'i' } },
  -- ['<M-[>'] = { desc = 'Copilot: Previous Suggestion', mode = { 'i' } },

  -- Default mappings having descriptions like :help &-default, :help v_#-default,...
  ['&'] = { desc = 'Repeat Last Substitute (Keep Flags)', mode = { 'n' } },
  ['*'] = { desc = 'Search Forward for Selection', mode = { 'x' } },
  ['#'] = { desc = 'Search Backward for Selection', mode = { 'x' } },
  ['<C-W>'] = { desc = 'Delete Previous Word (New Undo Point)', mode = { 'i' } },
  ['<C-U>'] = { desc = 'Delete Previous Word (New Undo Point)', mode = { 'i' } },
  ['<C-L>'] = { desc = 'Redraw (Clear Search Highlight, Update Diffs)', mode = { 'n' } },
  ['@'] = { desc = 'Execute Register on Each Selected Line', mode = { 'x' } },
  ['Q'] = { desc = 'Replay Last Macro on Each Selected Line', mode = { 'x' } },
}

return M
