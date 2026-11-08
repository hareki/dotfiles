--- The buffers picker's pieces; `format` also renders the rows of the tabs and harpoon pickers
--- @class features.search.snacks-nvim.sources.buffers
local M = {}

--- Format function for buffer picker: a modified indicator instead of buf number, type and flags
--- @param item snacks.picker.Item
--- @param picker snacks.Picker
--- @return snacks.picker.Highlight[] highlights
function M.format(item, picker)
  local ret = Snacks.picker.format.filename(item, picker)

  if item.name == '' and item.filetype ~= '' then
    vim.list_extend(ret, {
      { ' ' },
      { '[', 'SnacksPickerDelim' },
      { item.filetype, 'SnacksPickerFileType' },
      { ']', 'SnacksPickerDelim' },
    })
  end

  -- Runs per visible row on every render: vim.bo would switch into the autocmd window (~10us)
  if item.buf and vim.fn.getbufvar(item.buf, '&modified') == 1 then
    ret[#ret + 1] = { Conf.icons.file_status.MODIFIED, 'ModifiedIndicator' }
  end

  return ret
end

--- Transform function for buffer picker: flag modified buffers for the `modified` sort field
--- @param item snacks.picker.Item
--- @return nil
function M.transform(item)
  -- The matcher sorts from snacks' async loop, a fast event context where vim.bo raises
  -- E5560, so the sort key comes from the buffers finder's getbufinfo() snapshot
  item.modified = item.info.changed == 1
end

return M
