return {
  "nvim-treesitter/nvim-treesitter-context",
  opts = function(_, opts)
    Util.hls({
      TreesitterContextBottom = { bold = false, italic = false },
      TreesitterContext = { link = "DocumentHighlight" },
      TreesitterContextLineNumber = { link = "DocumentHighlight" },
    })

    return vim.tbl_deep_extend("force", opts, {
      max_lines = 4,
    })
  end,
}
