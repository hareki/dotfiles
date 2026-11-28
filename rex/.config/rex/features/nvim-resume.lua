-- [[ Neovim resume ]]

-- After a server restart, start a bare `nvim` again where Neovim reported one, and auto-session
-- restores the session for that directory. Neovim reports it from
-- `nvim/.config/nvim/lua/core/auto-session/rex-resume.lua`. A bare command takes no arguments, so
-- the rule trusts nothing that sources a file
rex.set('resume.trust.nvim', { command = { 'nvim' } })
