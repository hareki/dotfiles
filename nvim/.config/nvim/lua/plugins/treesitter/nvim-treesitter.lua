return {
  'nvim-treesitter/nvim-treesitter',
  version = false, -- last release is way too old and doesn't work on Windows
  build = ':TSUpdate',
  event = { 'LazyFile', 'VeryLazy' },
  lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
  cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
  keys = {
    { '<c-space>', desc = 'Increment Selection' },
    { '<bs>', desc = 'Decrement Selection', mode = 'x' },
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
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<C-space>',
        node_incremental = '<C-space>',
        scope_incremental = false,
        node_decremental = '<bs>',
      },
    },
    textobjects = {
      move = {
        enable = true,
        goto_next_start = {
          [']f'] = {
            query = '@function.outer',
            desc = 'Goto Next Function Start',
          },
          [']c'] = {
            query = '@class.outer',
            desc = 'Goto Next Class Start',
          },
          [']a'] = {
            query = '@parameter.inner',
            desc = 'Goto Next Parameter Start',
          },
        },
        goto_next_end = {
          [']F'] = {
            query = '@function.outer',
            desc = 'Goto Next Function End',
          },
          [']C'] = {
            query = '@class.outer',
            desc = 'Goto Next Class End',
          },
          [']A'] = {
            query = '@parameter.inner',
            desc = 'Goto Next Parameter End',
          },
        },
        goto_previous_start = {
          ['[f'] = {
            query = '@function.outer',
            desc = 'Goto Previous Function Start',
          },
          ['[c'] = {
            query = '@class.outer',
            desc = 'Goto Previous Class Start',
          },
          ['[a'] = {
            query = '@parameter.inner',
            desc = 'Goto Previous Parameter Start',
          },
        },
        goto_previous_end = {
          ['[F'] = {
            query = '@function.outer',
            desc = 'Goto Previous Function End',
          },
          ['[C'] = {
            query = '@class.outer',
            desc = 'Goto Previous Class End',
          },
          ['[A'] = {
            query = '@parameter.inner',
            desc = 'Goto Previous Parameter End',
          },
        },
      },
    },
  },
  config = function(_, opts)
    -- Notice the extra '.configs' part...
    require('nvim-treesitter.configs').setup(opts)
  end,
}
