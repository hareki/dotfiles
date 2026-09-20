local M = {}

local done = false

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
  if done then
    return
  end
  done = true

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
  -- the same colors nvim does.
  require('catppuccin').setup({
    transparent_background = true,
    default_integrations = false,
    custom_highlights = function(palette)
      return {
        ['@string.special.path'] = { fg = palette.text },
        ['@markup.quote'] = { fg = palette.text },
        ['@markup.italic'] = { fg = palette.flamingo, italic = true },
        ['@markup.strong'] = { fg = palette.flamingo, bold = true },
      }
    end,
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

  -- Keep EPIPE as a write error instead of a fatal signal so the emitter can
  -- exit cleanly when lazygit kills the render task mid-stream.
  pcall(function()
    vim.uv.new_signal():start('sigpipe', function() end)
  end)
end

return M
