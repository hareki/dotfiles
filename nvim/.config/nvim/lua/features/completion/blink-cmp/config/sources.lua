--- @class features.completion.blink-cmp.config.sources
local M = {}
--- @alias features.completion.blink-cmp.config.sources.TransformItems fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]

local EXTRA_WORDS_PATH =
  vim.fs.joinpath(vim.fn.stdpath('config'), 'lua/features/completion/blink-cmp/words')
local SNIPPETS_PATH =
  vim.fs.joinpath(vim.fn.stdpath('config'), 'lua/features/completion/blink-cmp/snippets')
-- One length for blink's filter and the search: a shorter prefix would search for items blink hides
local RIPGREP_MIN_KEYWORD_LENGTH = 3

--- A transform_items tagging every item with a custom kind: the icon resolves from
--- appearance.kind_icons[name], and kind_hl is set since blink derives it from the numeric kind
--- @param name string Kind name (e.g. 'History', 'Spell')
--- @return features.completion.blink-cmp.config.sources.TransformItems
local function custom_kind(name)
  local kind_hl = 'BlinkCmpKind' .. name

  return function(_, items)
    for _, item in ipairs(items) do
      item.kind_name = name
      item.kind_hl = kind_hl
    end
    return items
  end
end

M.default = {
  default = {
    'lsp',
    'snippets',
    'datword',
    'ripgrep',
    'buffer',
    -- 'minuet',
  },
  per_filetype = {
    lua = { inherit_defaults = true, 'lazydev' },
    markdown = { inherit_defaults = true, 'markdown' },
    gitcommit = { inherit_defaults = true, 'conventional_commits' },
  },

  providers = {
    lsp = { opts = { tailwind_color_icon = Conf.icons.misc.TAILWIND_COLOR } },

    snippets = {
      score_offset = -10,
      opts = { search_paths = { SNIPPETS_PATH } },
    },

    datword = {
      name = 'Datword',
      module = 'blink-cmp-dat-word',
      max_items = 3,
      min_keyword_length = 3,
      score_offset = -15,
      opts = {
        paths = {
          vim.fs.joinpath(EXTRA_WORDS_PATH, 'my-words.txt'),
          vim.fs.joinpath(EXTRA_WORDS_PATH, 'google-10000-english-usa-no-swears-long.txt'),
          vim.fs.joinpath(EXTRA_WORDS_PATH, 'monkeytype-commonly-misspelled.txt'),
          '/usr/share/dict/words',
        },
        spellsuggest = true,
      },
      transform_items = custom_kind('Spell'),
    },

    ripgrep = {
      name = 'Ripgrep',
      module = 'blink-ripgrep',
      max_items = 3,
      min_keyword_length = RIPGREP_MIN_KEYWORD_LENGTH,
      score_offset = -10,

      --- @module "blink-ripgrep"
      --- @type blink-ripgrep.Options
      opts = {
        prefix_min_len = RIPGREP_MIN_KEYWORD_LENGTH,
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
    },

    minuet = {
      name = 'Minuet',
      module = 'minuet.blink',
      timeout_ms = Conf.cmp.AI_CMP_TIMEOUT_MS,
      async = true,
      score_offset = -5,
    },

    cmdline = {
      max_items = 9,
    },

    cmdline_history = {
      -- Must match the source's nvim-cmp name
      name = 'cmdline_history',
      module = 'blink.compat.source',
      max_items = 9,
      transform_items = custom_kind('History'),
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
      transform_items = custom_kind('RenderMD'),
    },

    conventional_commits = {
      name = 'Conventional Commits',
      module = 'blink-cmp-conventional-commits',
    },
  },
}

M.cmdline = { 'cmdline', 'cmdline_history', 'buffer' }

return M
