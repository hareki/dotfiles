local typescript = require('core.lsp.nvim-lspconfig.utils.typescript')

local ts_config = {
  updateImportsOnFileMove = { enabled = 'always' },
}

-- PERF: Hardcode the mise tool root instead of resolving it with `mise where`,
-- since the version rarely changes anyway; packages are under lib/node_modules
local plugin_root =
  vim.fn.expand('~/.local/share/mise/installs/npm-styled-typescript-styled-plugin/1')
local npm_global_root = vim.fs.joinpath(plugin_root, 'lib/node_modules')

return {
  opts = {
    -- Parent-pid watchdog: vtsls exits and reaps its tsserver if this pid dies without LSP shutdown
    cmd = { 'vtsls', '--stdio', '--clientProcessId', tostring(vim.uv.os_getpid()) },
    root_dir = typescript.root_dir('vtsls'),
    settings = {
      typescript = ts_config,
      javascript = ts_config,
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
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
    },

    -- Client-side command, which `Client:exec_cmd` checks before asking the server
    commands = {
      ['_typescript.moveToFileRefactoring'] = function(command, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id) --[[@as vim.lsp.Client]]
        --- @type string, string, lsp.Range
        local action, uri, range = unpack(command.arguments --[[@as any[] ]])

        local function move(newf)
          client:request('workspace/executeCommand', {
            command = command.command,
            arguments = { action, uri, range, newf },
          })
        end

        local fname = vim.uri_to_fname(uri)
        client:request('workspace/executeCommand', {
          command = 'typescript.tsserverRequest',
          arguments = {
            'getMoveToRefactoringFileSuggestions',
            {
              file = fname,
              startLine = range.start.line + 1,
              startOffset = range.start.character + 1,
              endLine = range['end'].line + 1,
              endOffset = range['end'].character + 1,
            },
          },
        }, function(_, result)
          if not (result and result.body and result.body.files) then
            return
          end
          --- @type string[]
          local files = result.body.files
          table.insert(files, 1, 'Enter new path...')

          vim.ui.select(files, {
            prompt = 'Select Move Destination:',
            format_item = function(f)
              return vim.fn.fnamemodify(f, ':~:.')
            end,
          }, function(f)
            if f and f:find('^Enter new path') then
              local dir = vim.fs.dirname(fname)
              vim.ui.input({
                prompt = 'Enter Move Destination:',
                default = dir:sub(-1) == '/' and dir or dir .. '/',
                completion = 'file',
              }, function(newf)
                if newf then
                  move(newf)
                end
              end)
            elseif f then
              move(f)
            end
          end)
        end)
      end,
    },
  },

  setup = function()
    typescript.map_import_actions('vtsls', 'source.removeUnused.ts', 'source.addMissingImports.ts')
  end,
}
