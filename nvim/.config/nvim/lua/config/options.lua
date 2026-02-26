--  [[ Global options ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
local g = vim.g
local statusline = require('services.statusline')

g.mapleader = ' '
g.maplocalleader = ' '

-- Disable netrw
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

-- [[ Setting options ]]
-- See `:help opt`
-- For more options, you can see `:help option-list`

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.numberwidth = 1

opt.list = false -- Hide whitespace characters
opt.termguicolors = true -- True color support
opt.timeoutlen = 150 -- Lower than default (1000) to quickly trigger which-key
opt.updatetime = 300 -- Decrease update time
opt.pumblend = 0 -- Fully opaque popupmenu
opt.pumheight = 15 -- Maximum number of entries in a popup
opt.wrap = false -- Disable line wrapping
opt.mouse = 'a' -- Enable mouse mode
opt.showmode = false -- Don't show the mode, since it's already in the status line
opt.breakindent = true
opt.swapfile = false -- Don't use swapfiles
opt.inccommand = 'nosplit' -- Preview substitutions live, as you type!
opt.cursorline = true -- Show which line your cursor is on
opt.scrolloff = 6 -- Minimal number of screen lines to keep above and below the cursor.
opt.statuscolumn = '%l%s'
opt.signcolumn = 'yes:1' -- Always show the signcolumn, otherwise it would shift the text each time
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.laststatus = statusline.have_status_line() and 3 or 0 -- 3 = Global status line
opt.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
opt.tabstop = 2 -- Number of spaces tabs count for
opt.softtabstop = 2 -- Number of spaces tabs count for while performing editing operations
opt.expandtab = true -- Use spaces instead of tabs
opt.autoread = true -- Automatically read file changes from disk, also required for opencode.nvim `events.reload`
opt.showtabline = 0 -- Always hide the tabline

-- Use typos-lsp for spell checking, datword for suggestions
opt.spell = false
opt.spelllang = {}

-- Prevent changing cwd when navigating to files outside of cwd (e.g going to definition)
opt.viewoptions:remove('curdir')
opt.autochdir = false

-- https://github.com/sindrets/diffview.nvim?tab=readme-ov-file#tips-and-faq
opt.fillchars:append({ diff = '╱', eob = ' ', lastline = '.' })

-- Save undo history
opt.undofile = true
opt.undolevels = 2000

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
opt.ignorecase = true
opt.smartcase = true

-- Configure how new splits should be opened
opt.splitright = true
opt.splitbelow = true

-- If performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- a dialog will be raised asking if you wish to save the current file(s).
-- See `:help 'confirm'`
opt.confirm = true
opt.mousemoveevent = true

opt.guicursor = table.concat({
  -- Normal & Visual ⇒ solid block that starts blinking after 700 ms
  'n-v:block-blinkwait0-blinkon400-blinkoff250',
  -- Insert & Command-line ⇒ 25-cell vertical bar, blinks immediately
  'i-c-ci-ve:ver25-blinkwait0-blinkon400-blinkoff250',
  -- Replace modes ⇒ 20-cell underline, same blink timing
  'r-cr:hor20-blinkwait0-blinkon400-blinkoff250',
  -- Operator-pending ⇒ 50-cell underline, no blink (steady)
  'o:hor50',
}, ',')
