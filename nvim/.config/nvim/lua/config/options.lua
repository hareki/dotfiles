-- Must happen before plugins are loaded (otherwise wrong leader will be used)
local g = vim.g

g.mapleader = ' '
g.maplocalleader = ' '

-- Disable built-in language providers
g.loaded_node_provider = 0
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0

-- markdown.vim's [[ / ]] maps duplicate markdown.lua's, and the double unmap leaves a
-- silenced E31 in v:errmsg. The visual-mode pair is re-declared in config/autocmds.lua
g.no_markdown_maps = 1

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.numberwidth = 1

opt.termguicolors = true -- True color support
opt.updatetime = 300
opt.pumheight = 15 -- Maximum number of entries in a popup
opt.pumborder = 'rounded' -- Rounded border around the popup menu (right-click + native completion)
opt.wrap = false
opt.mouse = 'a'
opt.showmode = false -- Don't show the mode, since it's already in the status line
opt.breakindent = true
opt.swapfile = false
opt.cursorline = true
opt.scrolloff = 6 -- Minimal number of screen lines to keep above and below the cursor.
-- Line numbers like the built-in %l item, but with the cursor line's number right-aligned too
opt.statuscolumn = '%=%{v:virtnum ? "" : &rnu && v:relnum ? v:relnum'
  .. ' : &nu ? v:lnum : &rnu ? 0 : ""}%s'
opt.signcolumn = 'yes:1' -- Always show the signcolumn, otherwise it would shift the text each time
opt.wildmode = 'longest:full,full'
opt.winminwidth = 5
opt.laststatus = 3 -- 3 = Global status line
opt.shiftwidth = 2 -- Number of spaces to use for each step of (auto)indent
opt.tabstop = 2 -- Number of spaces tabs count for
opt.softtabstop = 2 -- Number of spaces tabs count for while performing editing operations
opt.expandtab = true -- Use spaces instead of tabs
opt.showtabline = 0 -- Always hide the tabline
opt.linebreak = true -- Wrap words, not characters (mid-word wrapping) when wrap mode is on

-- Use typos-lsp for spell checking, datword for suggestions
opt.spelllang = {}

-- Prevent changing cwd when navigating to files outside of cwd (e.g. going to definition)
opt.viewoptions:remove('curdir')

-- Diagonal hatch fill for deleted/filler lines in diff views (e.g. codediff)
opt.fillchars:append({ diff = Conf.icons.fillchars.DIFF, eob = ' ', lastline = '.' })

-- Host tools launching nvim as their editor (NVIM_INTEGRATION) show their label in place of lualine
local integration = UI.statusline.integration
if integration then
  opt.statusline =
    string.format(' %%#StatusLineIntegration#%s %s', integration.icon, integration.label)
end

opt.undofile = true
opt.undolevels = 2000

-- Case-insensitive search unless the pattern has \C or a capital letter
opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true

-- Ask to save instead of failing on unsaved changes (like `:q`)
opt.confirm = true
opt.mousemoveevent = true

opt.guicursor = table.concat({
  -- Normal & Visual => solid block, blinks immediately (blinkwait0)
  'n-v:block-blinkwait0-blinkon400-blinkoff250',
  -- Insert & Command-line => 25%-width vertical bar, same blink timing
  'i-c-ci-ve:ver25-blinkwait0-blinkon400-blinkoff250',
  -- Replace modes => 20%-height underline, same blink timing
  'r-cr:hor20-blinkwait0-blinkon400-blinkoff250',
  -- Operator-pending => 50%-height underline, no blink (steady)
  'o:hor50',
}, ',')
