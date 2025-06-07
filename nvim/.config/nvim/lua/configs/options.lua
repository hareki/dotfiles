--  [[ Global options ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help opt`
-- For more options, you can see `:help option-list`

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.guicursor = "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkon1"
opt.list = false                   -- Hide whitespace characters
opt.spell = true                   -- Keep it true to use cmp-spell, but hide the undercurl
opt.spelllang = { 'en_us' }        -- Set the spell checking language to English (US)
opt.termguicolors = true           -- True color support
opt.timeoutlen = 300               -- Lower than default (1000) to quickly trigger which-key
opt.pumblend = 0                   -- Fully opaque popupmenu
opt.pumheight = 15                 -- Maximum number of entries in a popup
opt.wrap = false                   -- Disable line wrapping
opt.mouse = 'a'                    -- Enable mouse mode
opt.showmode = false               -- Don't show the mode, since it's already in the status line
opt.breakindent = true
opt.inccommand = 'split'           -- Preview substitutions live, as you type!
opt.cursorline = true              -- Show which line your cursor is on
opt.scrolloff = 6                  -- Minimal number of screen lines to keep above and below the cursor.
opt.signcolumn = "yes"             -- Always show the signcolumn, otherwise it would shift the text each time
opt.updatetime = 250               -- Decrease update time
opt.timeoutlen = 300               -- Decrease mapped sequence wait time
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5                -- Minimum window width

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
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
opt.confirm = true
