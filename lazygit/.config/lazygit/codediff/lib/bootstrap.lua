local M = {}

local data = vim.fn.stdpath('data')
local config = vim.fn.stdpath('config')

--- Every path a render depends on, in one table: the ones setup() loads from,
--- plus the artifacts whose change has to recycle a running daemon. daemon.lua
--- fingerprints this whole table rather than a hand-picked subset of it, so a
--- dependency added here cannot be one the staleness check forgot.
M.paths = {
  site = vim.fs.joinpath(data, 'site'),
  parsers = vim.fs.joinpath(data, 'site/parser'),
  treesitter = vim.fs.joinpath(data, 'lazy/nvim-treesitter'),
  catppuccin = vim.fs.joinpath(data, 'lazy/catppuccin'),
  codediff = vim.fs.joinpath(data, 'lazy/codediff.nvim'),
  -- Bumped whenever codediff.nvim (and its native diff library) updates.
  codediff_version = vim.fs.joinpath(data, 'lazy/codediff.nvim/VERSION'),
  -- The editor's filetype-rules module that setup() sources below: its
  -- detection rules and ft => language aliases shape every render, so an edit
  -- must recycle the daemon like any renderer source.
  filetype_rules = vim.fs.joinpath(config, 'lua/config/filetypes/init.lua'),
  -- The editor's treesitter @capture overrides, which setup() hands to
  -- catppuccin below: they decide what a highlighted diff row looks like, so an
  -- edit must recycle the daemon like any renderer source.
  capture_highlights = vim.fs.joinpath(config, 'lua/config/treesitter-highlights.lua'),
  -- Rewritten by every lazy update, so one stat covers the plugins above
  -- changing under a running daemon: an update that only rewrites existing
  -- files leaves their directory mtimes untouched.
  plugin_lock = vim.fs.joinpath(config, 'lazy-lock.json'),
}

--- Minimal environment for treesitter-quality highlighting without loading the
--- user's full nvim config: parsers + queries from the site dir, catppuccin for
--- @capture colors, codediff.nvim for the diff engine + highlight groups, and
--- the same filetype=>language aliases the editor uses.
function M.setup()
  -- This LuaJIT (arm64 macOS) cannot map a second machine-code area, so once
  -- the default one is full, the next trace flushes every compiled one: ~110
  -- full flushes per 76 renders of real diffs, a quarter of the render time.
  -- One area sized for the renderer's working set (a few thousand traces)
  -- keeps them.
  jit.opt.start('sizemcode=2048', 'maxmcode=2048', 'maxtrace=8000')

  -- site must be PREPENDED: query.get() takes the first highlights.scm in rtp
  -- order, and $VIMRUNTIME ships older queries for lua/vim/markdown/c that
  -- would otherwise shadow nvim-treesitter's.
  vim.opt.runtimepath:prepend(M.paths.site)
  vim.opt.runtimepath:append(M.paths.treesitter)
  vim.opt.runtimepath:append(M.paths.treesitter .. '/runtime')
  vim.opt.runtimepath:append(M.paths.catppuccin)
  vim.opt.runtimepath:append(M.paths.codediff)

  vim.o.termguicolors = true

  -- Mirror the subset of the editor's catppuccin setup that affects the groups
  -- this renderer reads (Diff* backgrounds, @capture colors), so lazygit shows
  -- the same colors nvim does. The @capture overrides are loaded from the
  -- module the editor's own colorscheme spec requires rather than transcribed,
  -- which is what keeps the two from drifting; guarded like the filetype rules
  -- below, because a render must never fail over four colors.
  local ok_captures, capture_highlights = pcall(dofile, M.paths.capture_highlights)
  require('catppuccin').setup({
    -- Not the editor's compile cache: catppuccin recompiles every flavour
    -- whenever its options hash differs from the cached one, so sharing the
    -- directory made the renderer and the editor recompile each other's.
    compile_path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'catppuccin-codediff'),
    transparent_background = true,
    default_integrations = false,
    custom_highlights = ok_captures and capture_highlights or nil,
  })
  vim.cmd.colorscheme('catppuccin-mocha')

  -- requiring codediff.core.diff may auto-download the native library when it
  -- thinks it is outdated; the render daemon must never touch the network.
  vim.env.VSCODE_DIFF_NO_AUTO_INSTALL = '1'
  -- Defines CodeDiffLine*/CodeDiffChar* from the active colorscheme, which
  -- theme.load_diff_colors() then reads back.
  require('codediff.ui.highlights').setup()
  require('lib.theme').load_diff_colors()

  -- Plugin files are not auto-sourced in --clean headless mode. These two are
  -- required: filetypes.lua registers ft=>lang aliases (typescriptreact=>tsx,
  -- sh=>bash, ...), query_predicates.lua defines the custom predicates that
  -- nvim-treesitter's query files use.
  vim.cmd('runtime! plugin/filetypes.lua plugin/query_predicates.lua')

  -- The editor's own vim.filetype.add() rules and its filetype => treesitter
  -- language aliases (mdx, handlebars, htmlangular) live in the user config,
  -- which --clean never loads, so a path with no builtin rule (a ghostty
  -- config, a .mdx file) resolves to no filetype here and renders
  -- unhighlighted. Sourcing the one module that owns both keeps them from
  -- drifting out of sync; guarded because a render must never fail over
  -- filetype detection alone.
  pcall(dofile, M.paths.filetype_rules)
end

return M
