return {
  UI.catppuccin(function(palette, _, extension)
    return {
      GitConflictCurrentLabel = { bg = extension.conflict_current_label, fg = palette.text },
      GitConflictCurrent = { bg = extension.conflict_current },

      GitConflictAncestorLabel = { bg = palette.surface2, fg = palette.text },
      GitConflictAncestor = { bg = palette.surface1 },

      GitConflictIncomingLabel = { bg = extension.conflict_incoming_label, fg = palette.text },
      GitConflictIncoming = { bg = extension.conflict_incoming },

      -- Targets of the conflict window's 'winhighlight' redirect (see utils.lua)
      GitConflictDocumentHighlight = { bg = extension.surface15 },
      GitConflictBlame = { fg = palette.subtext0 },
    }
  end),

  {
    'hareki/git-conflict.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = function()
      local codediff_utils = require('features.git.codediff-nvim.utils')
      return {
        default_mappings = false,
        default_commands = false,
        -- Stay dormant in codediff tabs, which have their own 3-way merge UI
        cond = function()
          return not codediff_utils.is_codediff_tab(vim.api.nvim_get_current_tabpage())
        end,
      }
    end,

    config = function(_, opts)
      local plugin = require('git-conflict')
      plugin.setup(opts)

      local utils = require('features.git.git-conflict-nvim.utils')
      utils.setup()
    end,
  },
}
