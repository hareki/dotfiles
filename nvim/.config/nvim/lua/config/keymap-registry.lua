--- @class config.keymap-registry
local M = {}

--- Descs for Neovim's default maps, retitled in normal mode unless `mode` lists others
--- @type table<string, { desc: string, mode?: string[] }>
M.DESC_OVERRIDES = {
  ['[<leader>'] = { desc = 'Add Empty Line Above Cursor' },
  [']<leader>'] = { desc = 'Add Empty Line Below Cursor' },
  ['grn'] = { desc = 'LSP: Rename' },
  ['grr'] = { desc = 'LSP: References' },
  ['gO'] = { desc = 'LSP: Document Symbol' },
  ['gri'] = { desc = 'LSP: Implementation' },
  ['grt'] = { desc = 'LSP: Type Definition' },
  ['gra'] = { desc = 'LSP: Code Actions', mode = { 'n', 'x' } },
  ['grx'] = { desc = 'LSP: Run Code Lens' },
  ['<C-S>'] = { desc = 'LSP: Signature Help', mode = { 's', 'i' } },
  ['gx'] = { desc = 'Open URL' },

  -- Default mappings having descriptions like :help &-default, :help v_#-default,...
  ['&'] = { desc = 'Repeat Last Substitute (Keep Flags)' },
  ['*'] = { desc = 'Search Forward for Selection', mode = { 'x' } },
  ['#'] = { desc = 'Search Backward for Selection', mode = { 'x' } },
  ['<C-W>'] = { desc = 'Delete Previous Word (New Undo Point)', mode = { 'i' } },
  ['<C-U>'] = { desc = 'Delete Text Before Cursor (New Undo Point)', mode = { 'i' } },
  ['<C-L>'] = { desc = 'Redraw (Clear Search Highlight, Update Diffs)' },
  ['@'] = { desc = 'Execute Register on Each Selected Line', mode = { 'x' } },
  ['Q'] = { desc = 'Replay Last Macro on Each Selected Line', mode = { 'x' } },
  [']d'] = { desc = 'Next Diagnostic' },
  ['[d'] = { desc = 'Previous Diagnostic' },
  [']D'] = { desc = 'Last Diagnostic' },
  ['[D'] = { desc = 'First Diagnostic' },
  ['<C-W>d'] = { desc = 'Show Diagnostics Under Cursor' },
  ['<C-W><C-D>'] = { desc = 'Show Diagnostics Under Cursor' },
  [']b'] = { desc = 'Next Buffer' },
  ['[b'] = { desc = 'Previous Buffer' },
  [']B'] = { desc = 'Last Buffer' },
  ['[B'] = { desc = 'First Buffer' },
  [']n'] = { desc = 'Select Next Node', mode = { 'x' } },
  ['[n'] = { desc = 'Select Previous Node', mode = { 'x' } },
  [']N'] = { desc = 'Expand Selection to Next Node', mode = { 'x' } },
  ['[N'] = { desc = 'Expand Selection to Previous Node', mode = { 'x' } },
  ['gc'] = { desc = 'Comment Block', mode = { 'o' } },
  ['<Tab>'] = { desc = 'Next Snippet Placeholder', mode = { 'i', 's' } },
  ['<S-Tab>'] = { desc = 'Previous Snippet Placeholder', mode = { 'i', 's' } },
}

--- Fold-key { key, desc } pairs shared by the which-key preset's z group and the keymaps picker
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
