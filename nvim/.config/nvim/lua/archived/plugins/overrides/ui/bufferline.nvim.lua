return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "<A-S-h>", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "<A-S-l>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    { "<A-S-p>", "<cmd>BufferLineTogglePin<cr>", desc = "Toggle pin" },
  },
  opts = function(_, opts)
    local palette = Util.get_palette()

    local bg = palette.base
    local blue = palette.blue
    local green = palette.green

    local normal_selected_text = palette.text
    local normal_unselected_text = palette.overlay0

    -- "hint", "info", "warning", "error": diagnostic variations
    -- "duplicate": prefix for duplicate file names at different paths
    -- "buffer": normal (bare bone) variations
    -- no suffix: normal (bare bone) state, doesn't get selected by any means
    -- "visible": buffer gets selected (current buffer), but not focused (eg: focusing neo-tree)
    -- "selected": currently selected and focused
    local get_selected_highlights = function()
      local sp = blue
      local result = {}

      local base_highlights = {
        bg = bg,
        bold = true,
        italic = false,
      }

      local visible_highlights = {
        bg = bg,
        bold = true,
        fg = normal_selected_text,
      }

      local selected_highlights = {
        bg = bg,
        bold = true,

        sp = sp,
        italic = false,
      }

      local diagnostic_variations = { "hint", "info", "warning", "error" }
      for _, label in ipairs(diagnostic_variations) do
        result[label] = base_highlights
        result[label .. "_visible"] = visible_highlights
        result[label .. "_selected"] = selected_highlights

        result[label .. "_diagnostic"] = base_highlights
        result[label .. "_diagnostic_visible"] = visible_highlights
        result[label .. "_diagnostic_selected"] = selected_highlights
      end

      result["indicator_visible"] = visible_highlights
      result["indicator_selected"] = selected_highlights

      result["duplicate"] = vim.tbl_extend("force", base_highlights, {
        bold = false,
        italic = true,
      })

      result["duplicate_visible"] = vim.tbl_extend("force", visible_highlights, {
        bold = false,
        italic = true,
        fg = normal_unselected_text,
      })

      result["duplicate_selected"] = vim.tbl_extend("force", selected_highlights, {
        bold = false,
        italic = true,
      })

      result["modified"] = vim.tbl_extend("force", base_highlights, {
        fg = green,
      })

      result["modified_visible"] = vim.tbl_extend("force", visible_highlights, {
        fg = green,
      })

      result["modified_selected"] = vim.tbl_extend("force", selected_highlights, {
        fg = green,
      })

      -- Normal
      result["buffer"] = base_highlights
      result["buffer_visible"] = visible_highlights
      result["buffer_selected"] = selected_highlights
      result["modified"] = base_highlights

      result["numbers"] = base_highlights

      return result
    end

    Util.highlights({
      BufferLineBuffer = {
        bg = palette.base,
      },
      BufferLineOffsetText = { bold = true, bg = palette.mantle },
    })

    return vim.tbl_deep_extend("force", opts, {
      options = {
        always_show_bufferline = true,
        max_name_length = 999,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            text_align = "center",
            highlight = "BufferLineOffsetText",
          },
        },

        indicator = {
          style = "underline",
        },
        color_icons = true,
        show_buffer_close_icons = false,
      },

      highlights = vim.tbl_extend("force", {
        separator = {
          fg = bg,
          bg = bg,
        },

        background = {
          bg = bg,
          bold = true,
        },
        fill = {
          bg = bg,
        },
      }, get_selected_highlights()),
    })
  end,
}
