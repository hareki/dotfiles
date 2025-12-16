local mappings = {
  incremental = '<C-Space>',
  decremental = '<BS>',
}

return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
  branch = 'master', -- The new "main" branch is immature, tree-sitter-styled breaks, colors look weird
  version = false, -- Last release is way too old and doesn't work on Windows
  keys = {
    { mappings.incremental, desc = 'Incremental Selection' },
    { mappings.decremental, desc = 'Decremental Selection', mode = 'x' },
  },
  opts_extend = { 'ensure_installed' },
  ---@type TSConfig
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    highlight = { enable = true },
    indent = { enable = true },
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
      'styled',
      'scss',
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = mappings.incremental,
        node_incremental = mappings.incremental,
        scope_incremental = false,
        node_decremental = mappings.decremental,
      },
    },
    textobjects = {
      move = {
        enable = true,
        goto_next_start = {
          [']f'] = {
            query = '@function.outer',
            desc = 'Go to Next Function Start',
          },
          [']c'] = {
            query = '@class.outer',
            desc = 'Go to Next Class Start',
          },
          [']a'] = {
            query = '@parameter.inner',
            desc = 'Go to Next Parameter Start',
          },
        },
        goto_next_end = {
          [']F'] = {
            query = '@function.outer',
            desc = 'Go to Next Function End',
          },
          [']C'] = {
            query = '@class.outer',
            desc = 'Go to Next Class End',
          },
          [']A'] = {
            query = '@parameter.inner',
            desc = 'Go to Next Parameter End',
          },
        },
        goto_previous_start = {
          ['[f'] = {
            query = '@function.outer',
            desc = 'Go to Previous Function Start',
          },
          ['[c'] = {
            query = '@class.outer',
            desc = 'Go to Previous Class Start',
          },
          ['[a'] = {
            query = '@parameter.inner',
            desc = 'Go to Previous Parameter Start',
          },
        },
        goto_previous_end = {
          ['[F'] = {
            query = '@function.outer',
            desc = 'Go to Previous Function End',
          },
          ['[C'] = {
            query = '@class.outer',
            desc = 'Go to Previous Class End',
          },
          ['[A'] = {
            query = '@parameter.inner',
            desc = 'Go to Previous Parameter End',
          },
        },
      },
    },
  },
}
