return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  version = false,
  build = ':TSUpdate | TSInstallAll',
  cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall', 'TSInstallAll' },
  event = { 'BufReadPost', 'BufNewFile' },

  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    vim.api.nvim_create_user_command('TSInstallAll', function()
      local spec = require('lazy.core.config').plugins['nvim-treesitter']
      local opts = type(spec.opts) == 'table' and spec.opts or {}
      local treesitter = require('nvim-treesitter')

      treesitter.install(opts.ensure_installed)
    end, {})
  end,

  opts = {
    ensure_installed = {
      'bash',
      'c',
      'diff',
      'html',
      'javascript',
      'jsdoc',
      'json',
      'jsonc',
      'lua',
      'luadoc',
      'luap',
      'markdown',
      'markdown_inline',
      'printf',
      'python',
      'query',
      'regex',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'xml',
      'yaml',
      'css',
      'scss',
      'styled',
      'zsh',
      'gitcommit',
    },
  },
}
