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
