--- @class blink-cmp.config.sources
local M = {}

local utils = require('features.completion.blink-cmp.utils')

local history = utils.register_kind('History')
local spell = utils.register_kind('Spell')
local render_markdown = utils.register_kind('RenderMD')

local extra_words_path = vim.fn.stdpath('config') .. '/words'
local word_paths = {
  builtin = '/usr/share/dict/words',
  google = extra_words_path .. '/google-10000-english-usa-no-swears-long.txt',
  monkeytype = extra_words_path .. '/monkeytype-commonly-misspelled.txt',
  my_words = extra_words_path .. '/my-words.txt',
}

M.default = {
  default = vim.tbl_filter(function(s)
    return s ~= nil
  end, {
    'lsp',
    'snippets',
    'datword',
    'ripgrep',
    'buffer',
    'minuet',
  }),
  per_filetype = {
    lua = { inherit_defaults = true, 'lazydev' },
    markdown = { inherit_defaults = true, 'markdown' },
    gitcommit = { inherit_defaults = true, 'conventional_commits' },
  },

  providers = {
    lsp = { opts = { tailwind_color_icon = Conf.Icons.misc.tailwind_color } },

    datword = {
      name = 'Datword',
      module = 'blink-cmp-dat-word',
      max_items = 3,
      min_keyword_length = 3,
      score_offset = -20,
      opts = {
        paths = {
          word_paths.my_words,
          word_paths.google,
          word_paths.monkeytype,
          word_paths.builtin,
        },
        spellsuggest = true,
      },
      transform_items = spell.transform_items,
    },

    ripgrep = {
      name = 'Ripgrep',
      module = 'blink-ripgrep',
      max_items = 3,
      min_keyword_length = Conf.Cmp.RIPGREP_MIN_KEYWORD_LENGTH,
      score_offset = -10,

      --- @module "blink-ripgrep"
      --- @type blink-ripgrep.Options
      opts = {
        prefix_min_len = Conf.Cmp.RIPGREP_MIN_KEYWORD_LENGTH,
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
        local is_ignored_filetype = filetype == '' or filetype == 'NvimTree' -- NvimTree live_filter has a blank filetype

        return not is_ignored_filetype
      end,
    },

    minuet = {
      name = 'Minuet',
      module = 'minuet.blink',
      -- With minuet `add_single_line_entry` we might get more than this
      -- max_items = Conf.Cmp.ai_cmp_max_items,
      timeout_ms = Conf.Cmp.AI_CMP_TIMEOUT_MS,
      async = true,
      score_offset = -100,
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
      --- @module 'blink-cmp-conventional-commits'
      --- @type blink-cmp-conventional-commits.Options
      opts = {},
    },
  },
}

M.cmdline = { 'cmdline', 'cmdline_history', 'buffer' }

return M
