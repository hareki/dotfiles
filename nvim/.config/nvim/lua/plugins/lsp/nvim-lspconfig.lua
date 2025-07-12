return {
  'neovim/nvim-lspconfig',
  -- Don't use 'LazyFile' event, it will mess up the file type detection when opening a direectory with nvim
  -- We can either:
  -- 1. Use 'VeryLazy' event
  -- 2. Use 'BufReadPre' event
  -- 3 Putting vim.lsp.enable() in the init function
  -- https://www.reddit.com/r/neovim/comments/1l7pz1l/starting_from_0112_i_have_a_weird_issue
  event = 'VeryLazy',
  dependencies = { 'folke/lazydev.nvim' },
  config = function()
    vim.diagnostic.config({
      -- virtual_lines = true,
      virtual_lines = {
        current_line = true,
      },
      virtual_text = false,
      underline = true,
      update_in_insert = true,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = Constant.icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = Constant.icons.diagnostics.Warn,
          [vim.diagnostic.severity.HINT] = Constant.icons.diagnostics.Hint,
          [vim.diagnostic.severity.INFO] = Constant.icons.diagnostics.Info,
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
          [vim.diagnostic.severity.WARN] = 'WarningMsg',
        },
      },
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local function opts(desc)
          return {
            buffer = args.buf,
            desc = desc,
          }
        end

        local map = vim.keymap.set

        map('n', 'gd', function()
          require('telescope.builtin').lsp_definitions()
        end, opts('Go to definition'))

        map('n', 'gr', function()
          require('telescope.builtin').lsp_references()
        end, opts('References'))
        map('n', 'gD', vim.lsp.buf.definition, opts('Go to definition'))
        map('n', 'gR', vim.lsp.buf.references, opts('References'))

        map('n', 'gh', vim.lsp.buf.hover, opts('Hover'))
        map('n', '<leader>ca', require('actions-preview').code_actions, opts('Code action')) -- Ctrl + Z
        map('n', '<leader>cr', vim.lsp.buf.rename, opts('Rename')) -- F2
        map('n', ']]', function()
          Snacks.words.jump(vim.v.count1)
        end, opts('Next reference'))
        map('n', '[[', function()
          Snacks.words.jump(-vim.v.count1)
        end, opts('Previous reference'))
      end,
    })

    vim.lsp.enable({ 'lua_ls', 'vtsls', 'typos_lsp' })

    vim.lsp.config('typos_lsp', {
      init_options = {
        config = '~/.config/typos/typos.toml',
        diagnosticSeverity = 'Info',
      },
    })
  end,
}
