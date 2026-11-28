-- [[ Neovim resume ]]

-- After a server restart, start a bare `nvim` again where nvim's core/auto-session/rex-resume.lua
-- reported one, for auto-session to restore. The rule takes no arguments, so no file gets sourced
rex.set('resume.trust.nvim', { command = { 'nvim' } })
