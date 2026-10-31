local typescript = require('core.lsp.nvim-lspconfig.utils.typescript')

return {
  opts = {
    -- Never upstream's lookup: it can land on a PATH tsc, and vim.lsp.config reloads lsp/tsc.lua on
    -- every resolve, so a wrapped root_dir's binary cache never reaches the resolved cmd
    cmd = function(dispatchers, config)
      local tsc = vim.fs.joinpath(config.root_dir, 'node_modules/.bin/tsc')
      local exiting = false

      local rpc = vim.lsp.rpc.start(
        { tsc, '--lsp', '--stdio' },
        vim.tbl_extend('force', dispatchers, {
          -- tsc exits 1 on the `exit` notification (the spec says 0), so each clean stop would warn
          on_exit = function(code, signal)
            dispatchers.on_exit(exiting and 0 or code, signal)
          end,
        }),
        { cwd = config.root_dir }
      )

      local notify = rpc.notify
      rpc.notify = function(method, params)
        exiting = exiting or method == 'exit'
        return notify(method, params)
      end

      return rpc
    end,
    root_dir = typescript.root_dir('tsc'),
    reuse_client = typescript.reuse_client,
  },

  setup = function()
    -- The server has no add-missing-imports action; its Fix All is the closest match
    typescript.map_import_actions('tsc', 'source.removeUnusedImports', 'source.fixAll')
  end,
}
