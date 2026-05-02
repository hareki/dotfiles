return {
  'neovim/nvim-lspconfig',
  -- https://www.reddit.com/r/neovim/comments/1l7pz1l/starting_from_0112_i_have_a_weird_issue
  event = 'VeryLazy',
  config = function()
    local range_fix = require('plugins.core.lsp.nvim-lspconfig.utils.diagnostic_range_fix')
    local underline_hack = require('plugins.core.lsp.nvim-lspconfig.utils.diagnostic_underline_hack')
    local server_loader = require('plugins.core.lsp.nvim-lspconfig.utils.server_loader')

    local original_set = vim.diagnostic.set
    ---@param namespace integer The diagnostic namespace
    ---@param bufnr integer Buffer number
    ---@param diagnostics vim.Diagnostic[]
    ---@param opts? vim.diagnostic.Opts Display options to pass to |vim.diagnostic.show()|
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
      if diagnostics and #diagnostics > 0 then
        range_fix.apply(bufnr, diagnostics)
        underline_hack.apply(diagnostics)
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
      update_in_insert = false,
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
      group = vim.api.nvim_create_augroup('lsp_attach_keymaps', { clear = true }),
      callback = function(args)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, {
            buffer = args.buf,
            desc = desc,
          })
        end

        map('n', 'gd', function()
          Snacks.picker.lsp_definitions({
            include_current = true,
          })
        end, 'Go to Definition')

        map('n', 'gr', function()
          Snacks.picker.lsp_references({
            include_current = true,
            include_declaration = true,
          })
        end, 'Find References')

        map('n', 'gR', function()
          Snacks.picker.lsp_references({ filter = { buf = 0 } })
        end, 'Find References in Current Buffer')

        map({ 'n', 'x' }, 'gh', '<cmd>EagleWin<cr>', 'Open Eagle LSP and Diagnostics')
        map({ 'n', 'x' }, 'gH', '<cmd>EagleWinLineDiagnostic<cr>', 'Open Eagle Line Diagnostics')
        map({ 'n', 'x' }, '<leader>ca', function()
          local tiny_code_action = require('tiny-code-action')
          tiny_code_action.code_action({})
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

    -- Schedule vim.lsp.enable to yield to the UI, letting the buffer render before
    -- LSP servers start matching and attaching.
    local servers = {
      'marksman', -- Markdown
      'lua_ls', -- Lua
      'taplo', -- Toml
      'yamlls', -- Yaml
      'typos_lsp', -- Spell checker
      'eslint', -- JS/TS linter
      'jsonls', -- JSON
      'html', -- HTML
      'cssls', -- CSS
      'css_variables', -- CSS
      'stylua', -- Lua formatter
      'vtsls', -- TypeScript
      'tailwindcss', -- Tailwind
      'astro', -- Astro
    }

    vim.defer_fn(function()
      server_loader.load_all()
      vim.lsp.enable(servers)
    end, 75)
  end,
}
