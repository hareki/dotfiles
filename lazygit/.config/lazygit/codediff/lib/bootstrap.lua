local M = {}

local data = vim.fn.stdpath('data')
local config = vim.fn.stdpath('config')

--- Every path a render depends on: what setup() loads, plus what must recycle a running daemon.
--- daemon.lua fingerprints the whole table, so a path added here can't be one it forgot.
M.paths = {
  site = vim.fs.joinpath(data, 'site'),
  parsers = vim.fs.joinpath(data, 'site/parser'),
  treesitter = vim.fs.joinpath(data, 'lazy/nvim-treesitter'),
  catppuccin = vim.fs.joinpath(data, 'lazy/catppuccin'),
  codediff = vim.fs.joinpath(data, 'lazy/codediff.nvim'),
  -- The editor's filetype rules and ft => language aliases, which pick a path's parser in setup().
  filetype_rules = vim.fs.joinpath(config, 'lua/config/filetypes/init.lua'),
  language_aliases = vim.fs.joinpath(config, 'lua/config/filetypes/languages.lua'),
  -- The editor's @capture overrides, which setup() hands to catppuccin for a diff row's colors.
  capture_highlights = vim.fs.joinpath(config, 'lua/config/treesitter-highlights.lua'),
  -- Rewritten by every lazy update, which can leave the plugin directories' mtimes untouched.
  plugin_lock = vim.fs.joinpath(config, 'lazy-lock.json'),
  -- On the rtp for its after/queries extensions: what the editor adds to a language shows in diffs.
  editor_after = vim.fs.joinpath(config, 'after'),
}

-- Each query file and directory too: an edit moves a file's mtime, an add or a removal its dir's.
local queries = vim.fs.joinpath(M.paths.editor_after, 'queries')
M.paths[queries] = queries
for name in vim.fs.dir(queries, { depth = 2 }) do
  local path = vim.fs.joinpath(queries, name)
  M.paths[path] = path
end

--- Highlighting without the user's config: parsers, catppuccin, codediff.nvim, the editor's rules.
function M.setup()
  -- This LuaJIT (arm64 macOS) can't map a second mcode area, so a full one flushes every trace:
  -- a quarter of the render time. One area sized for the renderer's few thousand traces keeps them.
  jit.opt.start('sizemcode=2048', 'maxmcode=2048', 'maxtrace=8000')

  -- site must be PREPENDED: query.get() takes the first highlights.scm; $VIMRUNTIME's are older.
  vim.opt.runtimepath:prepend(M.paths.site)
  vim.opt.runtimepath:append(M.paths.treesitter)
  vim.opt.runtimepath:append(M.paths.treesitter .. '/runtime')
  vim.opt.runtimepath:append(M.paths.catppuccin)
  vim.opt.runtimepath:append(M.paths.codediff)
  vim.opt.runtimepath:append(M.paths.editor_after)

  -- The editor's catppuccin setup, as far as this renderer reads it, with the editor's own @capture
  -- module so the two can't drift; guarded, since a render must never fail over four colors.
  local ok_captures, capture_highlights = pcall(dofile, M.paths.capture_highlights)
  require('catppuccin').setup({
    -- Its own compile cache: sharing the editor's made each recompile on the other's options hash.
    compile_path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'catppuccin-codediff'),
    transparent_background = true,
    default_integrations = false,
    custom_highlights = ok_captures and capture_highlights or nil,
  })
  vim.cmd.colorscheme('catppuccin-mocha')

  -- codediff.core.diff may download its native library on require; a render must stay offline.
  vim.env.VSCODE_DIFF_NO_AUTO_INSTALL = '1'
  -- Defines CodeDiffLine*/CodeDiffChar* from the colorscheme, for theme.load_diff_colors() to read.
  require('codediff.ui.highlights').setup()
  require('lib.theme').load_diff_colors()

  -- Not auto-sourced under --clean: nvim-treesitter's ft => lang aliases and query predicates.
  vim.cmd('runtime! plugin/filetypes.lua plugin/query_predicates.lua')

  -- The editor's filetype rules and language aliases (mdx => markdown) live in its config, which
  -- --clean skips: sourced from there so they can't drift, guarded so they never fail a render.
  pcall(dofile, M.paths.filetype_rules)
  pcall(function()
    local language_aliases = dofile(M.paths.language_aliases)
    language_aliases.register()
  end)
end

return M
