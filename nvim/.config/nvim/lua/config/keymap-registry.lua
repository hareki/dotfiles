--- @class config.keymap-registry
local M = {}

M.DESC_OVERRIDES = {
  ['[<leader>'] = { desc = 'Add Empty Line Above Cursor', mode = { 'n' } },
  [']<leader>'] = { desc = 'Add Empty Line Below Cursor', mode = { 'n' } },
  ['grn'] = { desc = 'LSP: Rename', mode = { 'n' } },
  ['grr'] = { desc = 'LSP: References', mode = { 'n' } },
  ['gO'] = { desc = 'LSP: Document Symbol', mode = { 'n' } },
  ['gri'] = { desc = 'LSP: Implementation', mode = { 'n' } },
  ['grt'] = { desc = 'LSP: Type Definition', mode = { 'n' } },
  ['gra'] = { desc = 'LSP: Code Actions', mode = { 'n', 'x' } },
  ['<C-S>'] = { desc = 'LSP: Signature Help', mode = { 's', 'i' } },
  ['gx'] = { desc = 'Open URL', mode = { 'n' } },

  -- Default mappings having descriptions like :help &-default, :help v_#-default,...
  ['&'] = { desc = 'Repeat Last Substitute (Keep Flags)', mode = { 'n' } },
  ['*'] = { desc = 'Search Forward for Selection', mode = { 'x' } },
  ['#'] = { desc = 'Search Backward for Selection', mode = { 'x' } },
  ['<C-W>'] = { desc = 'Delete Previous Word (New Undo Point)', mode = { 'i' } },
  ['<C-U>'] = { desc = 'Delete Text Before Cursor (New Undo Point)', mode = { 'i' } },
  ['<C-L>'] = { desc = 'Redraw (Clear Search Highlight, Update Diffs)', mode = { 'n' } },
  ['@'] = { desc = 'Execute Register on Each Selected Line', mode = { 'x' } },
  ['Q'] = { desc = 'Replay Last Macro on Each Selected Line', mode = { 'x' } },
  [']d'] = { desc = 'Next Diagnostic', mode = { 'n' } },
  ['[d'] = { desc = 'Previous Diagnostic', mode = { 'n' } },
  [']D'] = { desc = 'Last Diagnostic', mode = { 'n' } },
  ['[D'] = { desc = 'First Diagnostic', mode = { 'n' } },
  [']b'] = { desc = 'Next Buffer', mode = { 'n' } },
  ['[b'] = { desc = 'Previous Buffer', mode = { 'n' } },
  [']B'] = { desc = 'Last Buffer', mode = { 'n' } },
  ['[B'] = { desc = 'First Buffer', mode = { 'n' } },
}

--- Fold-key { key, desc } pairs: the which-key preset's z group, and the identity keymaps
--- features/search/snacks-nvim/init.lua registers so they show up in Snacks.picker.keymaps
M.FOLD_DESCS = {
  { 'za', 'Toggle Fold Under Cursor' },
  { 'zA', 'Toggle All Folds Under Cursor' },
  { 'zC', 'Close All Folds Under Cursor' },
  { 'zD', 'Delete All Folds Under Cursor' },
  { 'zE', 'Delete All Folds in File' },
  { 'zM', 'Close All Folds' },
  { 'zO', 'Open All Folds Under Cursor' },
  { 'zR', 'Open All Folds' },
  { 'zi', 'Toggle Folding' },
  { 'zm', 'Fold More' },
  { 'zo', 'Open Fold Under Cursor' },
  { 'zr', 'Fold Less' },
}

return M
