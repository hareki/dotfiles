--- Neovim's own keys as this config presents them: the defaults it has no use for deleted, the
--- maps Neovim sets retitled in CMOS 18 (its global defaults and the buffer-local maps of its
--- ftplugins and terminals), and the fold commands described through identity maps
--- @class config.builtin-keymaps
local M = {}

--- Neovim's vim-unimpaired style defaults this config has no use for, deleted in normal mode
M.UNUSED_DEFAULTS = {
  ']a',
  '[a',
  '[A',
  ']A',
  ']l',
  '[l',
  ']L',
  '[L',
  ']Q',
  '[Q',
  ']T',
  '[T',
  ']<C-L>',
  '[<C-L>',
  ']<C-Q>',
  '[<C-Q>',
  ']<C-T>',
  '[<C-T>',
}

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
  ['gx'] = { desc = 'Open URL', mode = { 'n', 'x' } },

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

--- Descs for the buffer-local maps Neovim sets, keyed by its own desc and retitled in normal mode
--- unless `mode` lists others. Matching that desc as well as the key leaves a plugin's or this
--- config's map on the same key its own title (the LSP ]] and [[ in core/lsp/nvim-lspconfig)
--- @type table<string, { lhs: string, desc: string, mode?: string[] }>
M.BUFFER_DESC_OVERRIDES = {
  -- $VIMRUNTIME/ftplugin/{help,markdown,checkhealth}.lua
  ['Show an Outline of the current buffer'] = {
    lhs = 'gO',
    desc = 'Show an Outline of the Current Buffer',
  },
  ['Jump to next section'] = { lhs = ']]', desc = 'Jump to Next Section' },
  ['Jump to previous section'] = { lhs = '[[', desc = 'Jump to Previous Section' },

  -- $VIMRUNTIME/ftplugin/nvim-pack.lua, in vim.pack's confirmation buffer
  ['Next plugin'] = { lhs = ']]', desc = 'Next Plugin', mode = { 'n', 'x' } },
  ['Previous plugin'] = { lhs = '[[', desc = 'Previous Plugin', mode = { 'n', 'x' } },

  -- Terminal buffers, from Neovim's TermOpen defaults
  ['Jump [count] shell prompts forward'] = {
    lhs = ']]',
    desc = 'Jump [count] Shell Prompts Forward',
    mode = { 'n', 'x', 'o' },
  },
  ['Jump [count] shell prompts backward'] = {
    lhs = '[[',
    desc = 'Jump [count] Shell Prompts Backward',
    mode = { 'n', 'x', 'o' },
  },
}

--- The filetypes whose ftplugin sets a BUFFER_DESC_OVERRIDES map, which the retitle waits for on
--- FileType; terminals set theirs on TermOpen
M.FTPLUGIN_FILETYPES = { 'checkhealth', 'help', 'markdown', 'nvim-pack' }

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

--- Give a map a new desc in place: mapset keeps its callback and flags, and puts a buffer-local
--- one in the current buffer
--- @param mode string
--- @param keymap table A dict from nvim_get_keymap() or maparg()
--- @param desc string
local function retitle(mode, keymap, desc)
  keymap.desc = desc
  vim.fn.mapset(mode, false, keymap)
end

--- Retitle the BUFFER_DESC_OVERRIDES maps Neovim set in `buf`
--- @param buf integer
local function retitle_buffer_maps(buf)
  vim.api.nvim_buf_call(buf, function()
    for neovim_desc, spec in pairs(M.BUFFER_DESC_OVERRIDES) do
      for _, mode in ipairs(spec.mode or { 'n' }) do
        local keymap = vim.fn.maparg(spec.lhs, mode, false, true)
        if keymap.buffer == 1 and keymap.desc == neovim_desc then
          retitle(mode, keymap, spec.desc)
        end
      end
    end
  end)
end

--- Apply the tables above, now and to each buffer Neovim maps later; safe to run again
function M.setup()
  -- Clean up unused keymaps
  for _, key in ipairs(M.UNUSED_DEFAULTS) do
    pcall(vim.keymap.del, 'n', key)
  end

  -- Retitle Neovim's own maps in place: which-key and the keymaps picker read the desc off the map.
  -- Only global ones here, so a buffer-local map on the same key (the gO outline in help, markdown
  -- and man) keeps its own title
  local retitles = {}
  for lhs, spec in pairs(M.DESC_OVERRIDES) do
    for _, mode in ipairs(spec.mode or { 'n' }) do
      retitles[mode] = retitles[mode] or {}
      -- Compared as keytrans() text: the table spells <leader>, lhsraw keeps <C-S> unsimplified
      retitles[mode][vim.fn.keytrans(vim.keycode(lhs))] = spec.desc
    end
  end
  for mode, descs in pairs(retitles) do
    for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
      local desc = descs[vim.fn.keytrans(keymap.lhsraw)]
      if desc then
        retitle(mode, keymap, desc)
      end
    end
  end

  -- A hack to get the fold keys, which are commands, to show in Snacks.picker.keymaps
  for _, fold in ipairs(M.FOLD_DESCS) do
    vim.keymap.set('n', fold[1], fold[1], { desc = fold[2] })
  end

  -- Neovim creates its ftplugin loader and terminal defaults before loading this config, and
  -- autocmds run in creation order: these see the maps they set
  local group =
    vim.api.nvim_create_augroup('config.builtin-keymaps.retitle-buffer-maps', { clear = true })
  local function on_maps_set(event)
    retitle_buffer_maps(event.buf)
  end
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = M.FTPLUGIN_FILETYPES,
    callback = on_maps_set,
  })
  vim.api.nvim_create_autocmd('TermOpen', { group = group, callback = on_maps_set })
  -- Buffers whose FileType or TermOpen came first: a file passed on the command line
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      retitle_buffer_maps(buf)
    end
  end
end

return M
