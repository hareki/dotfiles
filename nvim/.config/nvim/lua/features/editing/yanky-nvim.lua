--- @class snacks.picker
--- @field yanky fun(opts?: snacks.picker.Config | {}): snacks.Picker

return {
  UI.catppuccin(function(palette)
    return {
      YankySystemYanked = {
        fg = palette.base,
        bg = palette.yellow,
      },
      YankySystemPut = {
        fg = palette.base,
        bg = palette.peach,
      },
      YankyRegisterYanked = {
        fg = palette.base,
        bg = palette.blue,
      },
      YankyRegisterPut = {
        fg = palette.base,
        bg = palette.teal,
      },
    }
  end, 'yanky.nvim'),

  UI.which_key({
    rules = { pattern = 'yank', icon = Conf.icons.actions.YANK, color = 'yellow' },
  }),

  {
    'hareki/yanky.nvim',
    keys = {
      {
        '<leader>fy',
        function()
          Snacks.picker.yanky()
        end,
        desc = 'Open Yanky History',
      },
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank Text' },
      {
        'Y',
        '<Plug>(YankyYank)$',
        desc = 'Yank Text to End',
      },
      { 'h', '"+<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank Text to System Clipboard' },
      {
        'H',
        '"+<Plug>(YankyYank)$',
        desc = 'Yank to End to System Clipboard',
      },
      { 'p', '<Plug>(YankyPutAfter)', desc = 'Put Text' },
      { 'k', '"+<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put from System Clipboard' },

      -- Putting text in visual mode without overwriting the yank register: yanky's x-mode put runs
      -- Visual P (:help v_P) over the selection, keeping a typed `"x` prefix
      {
        'p',
        '<Plug>(YankyPutBefore)',
        mode = { 'x' },
        desc = 'Put Text',
      },
      {
        'P',
        '"0<Plug>(YankyPutBefore)',
        mode = { 'n', 'x' },
        desc = 'Put Text from Register 0',
      },

      {
        '<S-Up>',
        '<Plug>(YankyPreviousEntry)',
        desc = 'Previous Yanky Entry',
      },
      {
        '<S-Down>',
        '<Plug>(YankyNextEntry)',
        desc = 'Next Yanky Entry',
      },

      -- Trimmed (no indent/trailing); with a count, native linewise like dd below, since the count
      -- and `"x` prefix carry over to the returned keys (3yy still yanks 3 lines)
      {
        'yy',
        function()
          if vim.v.count1 > 1 then
            return 'yy'
          end

          -- The leading `^` motion would swallow a `"x` prefix, so re-apply it to the yank
          return '^"' .. vim.v.register .. 'yg_'
        end,
        expr = true,
        desc = 'Yank Line Trimmed',
      },
      {
        'hh',
        function()
          return vim.v.count1 > 1 and '"+yy' or '^"+yg_'
        end,
        expr = true,
        desc = 'Yank Line Trimmed to System Clipboard',
      },

      -- Op-pending `h` is the trimmed line, so `hh` split by 'timeoutlen' still yanks the same
      -- Uses ':' not <cmd>: op-pending visual text objects require the command-mode path
      {
        'h',
        function()
          -- `_` is the linewise [count]-lines motion, matching the counted hh
          return vim.v.count1 > 1 and '_' or ':<C-u>normal! ^vg_<CR>'
        end,
        mode = 'o',
        expr = true,
        desc = 'Trimmed Line',
      },
      {
        'dd',
        function()
          -- :normal! drops a typed `"x` prefix (`"_dd`), so pass it on, except `""`: unlike no
          -- prefix, it overwrites register 0 (P's source) and skips the small delete register
          local register = vim.v.register == '"' and '' or '"' .. vim.v.register

          -- Trimming only makes sense for a single line; with a count, fall
          -- back to native linewise semantics so 3dd still deletes 3 lines
          if vim.v.count1 > 1 then
            vim.cmd.normal({ args = { register .. vim.v.count1 .. 'dd' }, bang = true })
            return
          end

          vim.cmd.normal({ args = { '^' .. register .. 'dg_' }, bang = true }) -- Delete from first nonblank to last nonblank
          vim.cmd.normal({ args = { [["_dd]] }, bang = true }) -- Remove remaining indent + newline (blackhole)
        end,
        desc = 'Delete Line Trimmed',
      },
    },

    opts = function()
      return {
        highlight = {
          timer = 300,
        },
        system_clipboard = {
          sync_with_ring = false,
        },
      }
    end,
  },
}
