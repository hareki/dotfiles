return {
  'dmmulroy/tsc.nvim',
  cmd = { 'TSC' },
  opts = function()
    local noice_spinners = require('noice.util.spinners')
    local circle_full_frames = noice_spinners.spinners.circleFull.frames

    return {
      use_trouble_qflist = true,
      spinner = circle_full_frames,
      pretty_errors = false,
    }
  end,
}
