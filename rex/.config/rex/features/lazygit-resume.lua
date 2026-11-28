-- [[ lazygit resume ]]

-- After a server restart, start a bare `lazygit` again in the repo lazygit reported. The report
-- comes from the fork (`pkg/resume`), and only from a lazygit started without arguments
rex.set('resume.trust.lazygit', { command = { 'lazygit' } })
