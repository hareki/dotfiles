--- @class utils.ui.pill
local M = {}

--- Build pill-shaped virtual text chunks
--- @param content string The text content inside the pill
--- @param inner_hl string Highlight group for the pill content
--- @param outer_hl string Highlight group for the pill caps
--- @return table[] chunks Virtual text chunks: space, left cap, content, right cap
function M.virt_text(content, inner_hl, outer_hl)
  return {
    { ' ' },
    { Conf.icons.misc.PILL_LEFT, outer_hl },
    { content, inner_hl },
    { Conf.icons.misc.PILL_RIGHT, outer_hl },
  }
end

--- Calculate the total display width of a pill (space + caps + content)
--- @param content string The text content inside the pill
--- @return integer width Total display width in columns
function M.display_width(content)
  return 1
    + vim.fn.strdisplaywidth(Conf.icons.misc.PILL_LEFT)
    + vim.fn.strdisplaywidth(content)
    + vim.fn.strdisplaywidth(Conf.icons.misc.PILL_RIGHT)
end

return M
