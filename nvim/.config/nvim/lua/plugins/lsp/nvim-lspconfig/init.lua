return {
  'neovim/nvim-lspconfig',
  -- Don't use 'LazyFile' event, it will mess up the file type detection when opening a directory with nvim
  -- We can either:
  -- 1. Use 'VeryLazy' event
  -- 2. Use 'BufReadPre' event
  -- 3 Putting vim.lsp.enable() in the init function
  -- https://www.reddit.com/r/neovim/comments/1l7pz1l/starting_from_0112_i_have_a_weird_issue
  event = 'VeryLazy',
  dependencies = { 'folke/lazydev.nvim', 'mason-org/mason.nvim' },
  config = function()
    local utils = require('plugins.lsp.nvim-lspconfig.utils')

    local original_set = vim.diagnostic.set
    ---@param namespace integer The diagnostic namespace
    ---@param bufnr integer Buffer number
    ---@param diagnostics vim.Diagnostic[]
    ---@param opts? vim.diagnostic.Opts Display options to pass to |vim.diagnostic.show()|
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
      if diagnostics then
        utils.fix_all_diagnostic_ranges(bufnr, diagnostics)
        utils.apply_underline_hack(diagnostics)
      end

      return original_set(namespace, bufnr, diagnostics, opts)
    end

    vim.diagnostic.config({
      -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.Opts.VirtualLines
      -- virtual_lines = {
      --   current_line = true,
      -- },

      -- https://neovim.io/doc/user/diagnostic.html#vim.diagnostic.Opts.VirtualText
      -- virtual_text = {
      --   current_line = true,
      --   source = false,
      --   prefix = '●',
      -- },
      underline = true,
      update_in_insert = true,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '',
          [vim.diagnostic.severity.WARN] = '',
          [vim.diagnostic.severity.HINT] = '',
          [vim.diagnostic.severity.INFO] = '',
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
          [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
          [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
          [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
        },
      },
    })

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = args.buf,
            desc = desc,
          })
        end

        map('n', 'gd', function()
          Snacks.picker.lsp_definitions()
        end, 'Go to Definition')

        map('n', 'gr', function()
          Snacks.picker.lsp_references()
        end, 'Find References')

        map({ 'n', 'x' }, 'gh', '<CMD>EagleWin<CR>', 'Open Eagle LSP and Diagnostics')
        map({ 'n', 'x' }, 'gH', '<CMD>EagleWinLineDiagnostic<CR>', 'Open Eagle Line Diagnostics')
        map({ 'n', 'x' }, '<leader>ca', function()
          require('actions-preview').code_actions()
        end, 'Code Actions') -- Ctrl + Z
        map('n', '<leader>cr', vim.lsp.buf.rename, 'Rename') -- F2
        map('n', ']]', function()
          Snacks.words.jump(vim.v.count1)
        end, 'Next Reference')
        map('n', '[[', function()
          Snacks.words.jump(-vim.v.count1)
        end, 'Previous Reference')
      end,
    })

    utils.load_lsp_configs()

    vim.lsp.enable({
      'marksman', -- Markdown
      'lua_ls', -- Lua
      'taplo', -- Toml
      'yamlls', -- Yaml
      'typos_lsp', -- Spelling checker
      'eslint', -- JS/TS linter
      'jsonls', -- JSON
      'html', -- HTML
      'cssls', -- CSS
      'css_variables', -- CSS
      'copilot', -- GitHub Copilot
      'stylua', -- Lua formatter
      'vtsls', -- TypeScript
    })
  end,
}
