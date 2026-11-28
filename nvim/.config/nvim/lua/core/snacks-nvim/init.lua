--- @module 'core.snacks-nvim.terminals'
local terminals = Defer.on_exported_call('core.snacks-nvim.terminals')

-- Base spec: feature config lives in `snacks-nvim` fragments (docs/conventions/split-plugins.md)
return {
  UI.catppuccin.integration('snacks'),

  {
    'hareki/snacks.nvim',
    lazy = false,
    -- Set up early, as Snacks' README asks: some plugins rely on the autocmds its setup creates
    priority = Conf.priority.CORE,

    init = function()
      -- Search matches stay out of terminal windows. Set up on the first terminal, as no window has
      -- the redirect before one, which keeps core.snacks-nvim.terminals out of startup
      local group =
        vim.api.nvim_create_augroup('core.snacks-nvim.terminal-search', { clear = true })
      vim.api.nvim_create_autocmd('TermOpen', {
        group = group,
        once = true,
        callback = function(first)
          vim.api.nvim_create_autocmd({ 'BufWinEnter', 'TermOpen' }, {
            group = group,
            callback = function(event)
              for _, win in ipairs(vim.fn.win_findbuf(event.buf)) do
                terminals.sync_search_highlight(win)
              end
            end,
          })

          -- Snacks sets a terminal window's whole 'winhighlight' after BufWinEnter, and again each
          -- time it shows or updates the window; OptionSet runs in the window that changed
          vim.api.nvim_create_autocmd('OptionSet', {
            group = group,
            pattern = 'winhighlight',
            callback = function()
              terminals.sync_search_highlight(vim.api.nvim_get_current_win())
            end,
          })

          for _, win in ipairs(vim.fn.win_findbuf(first.buf)) do
            terminals.sync_search_highlight(win)
          end
        end,
      })
    end,

    keys = {
      {
        '<A-t>',
        terminals.toggle_floating,
        mode = { 'n', 'x', 't', 'i' },
        desc = 'Toggle Floating Terminal',
      },
    },

    opts = {
      bigfile = { enabled = true },

      styles = {
        float = { zindex = Conf.zindex.FLOAT },
        terminal = vim.tbl_extend('force', UI.layout.float_fn('lg'), {
          title = ' Terminal ',
          border = 'rounded',
          zindex = Conf.zindex.PANEL,
        }),
      },
    },
  },
}
