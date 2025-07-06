return {
  'neovim/nvim-lspconfig',
  event = 'LazyFile',
  dependencies = { 'folke/lazydev.nvim' },
  config = function()
    vim.diagnostic.config({
      virtual_lines = true,
      underline = true,
      update_in_insert = false,
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

        map('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
        map('n', 'gh', vim.lsp.buf.hover, opts('Hover'))
        map('n', 'gr', vim.lsp.buf.references, opts('References'))

        map('n', '<leader>ca', function()
          require('telescope') -- Force load telescope to override vim.ui.select
          vim.lsp.buf.code_action()
        end, opts('Code action')) -- Ctrl + Z

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
