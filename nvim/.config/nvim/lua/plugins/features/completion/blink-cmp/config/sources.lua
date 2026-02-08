---@class blink-cmp.config.sources
local M = {}

local utils = require('plugins.features.completion.blink-cmp.utils')
local limit = require('plugins.features.completion.blink-cmp.config.limit')

local history = utils.register_kind('History')
local spell = utils.register_kind('Spell')
local render_markdown = utils.register_kind('RenderMD')

local extra_words_path = vim.fn.stdpath('config') .. '/words'
local word_paths = {
  builtin = '/usr/share/dict/words',
  google = extra_words_path .. '/google-10000-english-usa-no-swears-long.txt',
  my_words = extra_words_path .. '/my-words.txt',
}

M.default = {
  default = { 'lsp', 'snippets', 'datword', 'ripgrep', 'path', 'buffer', 'copilot' },
  per_filetype = {
    lua = { inherit_defaults = true, 'lazydev' },
    markdown = { inherit_defaults = true, 'markdown' },
    gitcommit = { inherit_defaults = true, 'conventional_commits' },
  },

  providers = {
    lsp = { opts = { tailwind_color_icon = '' } },

    datword = {
      name = 'Datword',
      module = 'blink-cmp-dat-word',
      max_items = 3,
      min_keyword_length = 3,
      score_offset = -20,
      opts = {
        paths = { word_paths.my_words, word_paths.google, word_paths.builtin },
        spellsuggest = true,
      },
      transform_items = spell.transform_items,
    },

    ripgrep = {
      name = 'Ripgrep',
      module = 'blink-ripgrep',
      max_items = 3,
      min_keyword_length = limit.ripgrep_min_keyword_length,
      score_offset = -10,

      ---@module "blink-ripgrep"
      ---@type blink-ripgrep.Options
      opts = {
        prefix_min_len = limit.ripgrep_min_keyword_length,
        backend = {
          use = 'gitgrep',
          context_size = 6,
          gitgrep = {
            additional_gitgrep_options = {
              -- https://github.com/mikavilpas/blink-ripgrep.nvim/blob/main/documentation/ignore-files-from-git-grep.md
              ':(exclude,attr:blink-ripgrep-ignore)',
            },
          },
        },
      },
    },

    buffer = {
      max_items = 3,
      score_offset = -10,
      should_show_items = function()
        local filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        local is_ignored_filetype = vim.list_contains({ '', 'NvimTree' }, filetype) -- NvimTree live_filter has a blank filetype

        return not is_ignored_filetype
      end,
    },

    copilot = {
      name = 'Copilot',
      module = 'blink-copilot',
      max_items = limit.copilot_max_items,
      async = true,
      -- Wrap around the menu items to quickly access the suggestion items while prevent items shifting
      score_offset = -100,
      -- should_show_items = function(ctx)
      --   -- Only show items if 'copilot' is the sole provider to avoid distraction
      --   return ctx.providers[1] == 'copilot' and #ctx.providers == 1
      -- end,
    },

    cmdline = {
      min_keyword_length = utils.cmdline_min_keyword_length(0),
      max_items = 6,
    },

    cmdline_history = {
      -- IMPORTANT: use the same name as you would for nvim-cmp
      name = 'cmdline_history',
      module = 'blink.compat.source',
      max_items = 6,
      min_keyword_length = utils.cmdline_min_keyword_length(0),
      transform_items = history.transform_items,
    },

    lazydev = {
      name = 'LazyDev',
      module = 'lazydev.integrations.blink',
      max_items = 6,
      score_offset = 10,
    },

    markdown = {
      name = 'RenderMarkdown',
      module = 'render-markdown.integ.blink',
      max_items = 3,
      transform_items = render_markdown.transform_items,
    },

    conventional_commits = {
      name = 'Conventional Commits',
      module = 'blink-cmp-conventional-commits',
      ---@module 'blink-cmp-conventional-commits'
      ---@type blink-cmp-conventional-commits.Options
      opts = {},
    },
  },
}

M.cmdline = { 'cmdline', 'cmdline_history', 'buffer' }

return M
