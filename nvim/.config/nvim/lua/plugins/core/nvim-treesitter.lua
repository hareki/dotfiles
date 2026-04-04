return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  version = false,
  cmd = { 'TSUpdate', 'TSInstall', 'TSLog', 'TSUninstall' },
  event = { 'BufReadPost', 'BufNewFile' },

  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = '*',
      callback = function(args)
        local buf = args.buf
        pcall(vim.treesitter.start, buf)
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
      'astro',
    },
  },

  config = function(_, opts)
    local TS = require('nvim-treesitter')

    local installed = {}
    for _, lang in ipairs(TS.get_installed('parsers')) do
      installed[lang] = true
    end

    local missing = vim.tbl_filter(function(lang)
      return not installed[lang]
    end, opts.ensure_installed or {})

    if #missing > 0 then
      local lazy = require('lazy')
      -- Need tree-sitter-cli from mason
      lazy.load({ plugins = { 'mason.nvim' } })

      TS.install(missing, { summary = true }):await(function()
        TS.get_installed('parsers') -- refresh installed languages
      end)
    end
  end,
}
