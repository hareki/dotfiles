return {
  'hareki/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
  keys = {

    {
      '<leader>do',
      '<cmd>DiffviewOpen<cr>',
      desc = 'Open Diffview',
      silent = true,
    },
    {
      '<leader>df',
      '<cmd>DiffviewFileHistory %<cr>',
      desc = 'File History',
      silent = true,
    },
    {
      '<leader>dl',
      function()
        local git = require('utils.git')
        local current_commit = git.get_current_line_commit()

        if not current_commit then
          notifier.warn('No commit history for this line')
          return
        end

        git.diff_parent(current_commit)
      end,
      desc = 'Diff Current Line',
    },
    {
      '<leader>dt',
      function()
        require('utils.git').diff_parent()
      end,
      desc = 'Diff Parent',
    },
  },

  opts = function()
    local log_popup_config = require('utils.ui').popup_config('md')
    local actions = require('diffview.actions')
    local icons = require('configs.icons')
    local panel_win_config = {
      position = 'bottom',
      height = 12,
    }

    -- Common keymaps shared between view and file_panel
    local common_keymaps = {
      { 'n', '<leader>de', actions.toggle_files, { desc = 'Toggle File Panel' } },
      { 'n', 'gf', actions.goto_file_edit, { desc = 'Open File' } },
      { 'n', ']l', actions.cycle_layout, { desc = 'Cycle Layouts' } },
    }

    local view_conflict_keys = {
      { 'n', '<leader>co', actions.conflict_choose('ours'), { desc = 'Choose OURS' } },
      { 'n', '<leader>ct', actions.conflict_choose('theirs'), { desc = 'Choose THEIRS' } },
      { 'n', '<leader>cb', actions.conflict_choose('base'), { desc = 'Choose BASE' } },
      { 'n', '<leader>ca', actions.conflict_choose('all'), { desc = 'Choose ALL' } },
      { 'n', 'dx', actions.conflict_choose('none'), { desc = 'Delete the Conflict Region' } },
    }

    local panel_conflict_keys = {
      { 'n', '[x', actions.prev_conflict, { desc = 'Previous Conflict' } },
      { 'n', ']x', actions.next_conflict, { desc = 'Next Conflict' } },
      { 'n', '<leader>cO', actions.conflict_choose_all('ours'), { desc = 'Chosoe All OURS' } },
      { 'n', '<leader>cT', actions.conflict_choose_all('theirs'), { desc = 'Chosoe All THEIRS' } },
      { 'n', '<leader>cB', actions.conflict_choose_all('base'), { desc = 'Chosoe All BASE' } },
      { 'n', '<leader>cA', actions.conflict_choose_all('all'), { desc = 'Choose All WHOLE' } },
      { 'n', 'dX', actions.conflict_choose_all('none'), { desc = 'Delete All Conflict Regions' } },
    }

    local explorer_keys = {
      { 'n', '<Down>', actions.next_entry, { desc = 'Next File' } },
      { 'n', '<S-Down>', actions.select_next_entry, { desc = 'Next File' } },
      { 'n', '<Up>', actions.prev_entry, { desc = 'Previous File' } },
      { 'n', '<S-Up>', actions.select_prev_entry, { desc = 'Previous File' } },
      { 'n', '<CR>', actions.select_entry, { desc = 'Open Diff for Selected Entry' } },
      { 'n', '<2-LeftMouse>', actions.select_entry, { desc = 'Open Diff for Selected Entry' } },
      { 'n', '<Right>', actions.open_fold, { desc = 'Expand Node' } },
      { 'n', '<S-Right>', actions.open_all_folds, { desc = 'Expand All Nodes' } },
      { 'n', '<Left>', actions.close_fold, { desc = 'Collapse Node' } },
      { 'n', '<S-Left>', actions.close_all_folds, { desc = 'Collapse All Nodes' } },
      { 'n', 'L', actions.open_commit_log, { desc = 'Show Commit Details' } },
    }

    local list_extend = require('utils.common').list_extend
    local help_panel = function(id)
      return { 'n', 'g?', actions.help(id), { desc = 'Open the Help Panel' } }
    end

    return {
      enhanced_diff_hl = true,
      icons = {
        folder_closed = icons.explorer.folder,
        folder_open = icons.explorer.folder_open,
      },
      signs = {
        fold_closed = icons.explorer.collapsed,
        fold_open = icons.explorer.expanded,
      },
      file_panel = {
        win_config = panel_win_config,
      },
      file_history_panel = {
        win_config = panel_win_config,
      },
      commit_log_panel = {
        win_config = {
          type = 'float',
          border = 'rounded',
          col = log_popup_config.col,
          row = log_popup_config.row,
          width = log_popup_config.width,
          height = log_popup_config.height,
          title = ' Commit Details ',
          title_pos = 'center',
        },
      },
      view = {
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
      hooks = {
        view_opened = function(view)
          if view.class:name() == 'DiffView' then
            require('diffview.actions').toggle_files()
          end
        end,
      },
      keymaps = {
        disable_defaults = true,
        view = list_extend(common_keymaps, panel_conflict_keys, view_conflict_keys),

        diff1 = {
          help_panel({ 'view', 'diff1' }),
        },
        diff2 = {
          help_panel({ 'view', 'diff2' }),
        },
        diff3 = {
          help_panel({ 'view', 'diff3' }),
        },
        diff4 = {
          help_panel({ 'view', 'diff4' }),
        },
        -- --------------------------
        file_panel = list_extend(common_keymaps, explorer_keys, {
          help_panel('file_panel'),
          { 'n', ']v', actions.listing_style, { desc = 'Cycle Views' } }, -- List and Tree
          { 'n', '<C-r>', actions.refresh_files, { desc = 'Refresh' } },
        }),

        file_history_panel = list_extend(common_keymaps, explorer_keys, {
          help_panel('file_history_panel'),
          { 'n', 'g!', actions.options, { desc = 'Open the Option Panel' } },
          { 'n', 'y', actions.copy_hash, { desc = 'Copy Commit Hash' } },
        }),
        option_panel = {
          { 'n', '<tab>', actions.select_entry, { desc = 'Change Current Option' } },
          { 'n', 'q', actions.close, { desc = 'Close Panel' } },
          help_panel('option_panel'),
        },
        help_panel = {
          { 'n', 'q', actions.close, { desc = 'Close Help Menu' } },
          { 'n', '<esc>', actions.close, { desc = 'Close Help Menu' } },
        },
      },
    }
  end,
}
