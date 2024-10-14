-- Let's see if I feel uncomfortable without this plugin... Since I don't use it that much
if true then
  return {}
end

return {
  {
    "leafo/magick",
  },
  {
    "hareki/image.nvim",
    opts = {
      tmux_show_only_in_active_window = true,
    },
  },
}
