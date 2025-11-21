-- Refer to this to further configure vtsls:
-- https://www.lazyvim.org/extras/lang/typescript#nvim-lspconfig

local ts_config = {
  updateImportsOnFileMove = { enabled = 'always' },
  suggest = {
    completeFunctionCalls = true,
  },
  inlayHints = {
    enumMemberValues = { enabled = true },
    functionLikeReturnTypes = { enabled = true },
    parameterNames = { enabled = 'literals' },
    parameterTypes = { enabled = true },
    propertyDeclarationTypes = { enabled = true },
    variableTypes = { enabled = false },
  },
}

local js_config = ts_config

return {
  setup = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)

        if not (client and client.name == 'vtsls') then
          return
        end

        vim.keymap.set('n', '<leader>cu', function()
          vim.lsp.buf.code_action({
            apply = true,
            context = {
              only = { 'source.removeUnused.ts' },
              diagnostics = {},
            },
          })
        end, {
          buffer = args.buf,
          desc = 'Remove Unused Imports',
        })
      end,
    })
  end,

  opts = function()
    local npm_global_root = vim.fn.trim(vim.fn.system('npm root -g'))

    return {
      settings = {
        complete_function_calls = true,
        typescript = ts_config,
        javascript = js_config,
        vtsls = {
          enableMoveToFileCodeAction = true,
          autoUseWorkspaceTsdk = true,
          tsserver = {
            globalPlugins = {
              {
                name = '@styled/typescript-styled-plugin',
                location = npm_global_root,
                enableForWorkspaceTypeScriptVersions = true,
              },
            },
          },
          experimental = {
            maxInlayHintLength = 30,
            completion = {
              enableServerSideFuzzyMatch = true,
            },
          },
        },
      },
    }
  end,
}
