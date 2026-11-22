-- Rex.app keeps its settings in its macOS preferences (com.superlogical.rex), where no file can
-- set them. This is their record: each entry names a client.setting.* action and the value it
-- takes, and the Apply Settings action (features/apply-settings.lua) sets them all. So change a
-- setting here and apply it. One changed in the Settings window is lost at the next apply
return {
  -- [[ Themes ]]
  { 'themes.dark.palette', 'Catppuccin Mocha' },
  { 'themes.light.palette', 'merino-light' },

  -- [[ Interface ]]
  { 'interface.appearance.style', 'classic' },
  { 'interface.appearance.tint', true },
  { 'interface.appearance.glass', false },
  { 'interface.toolbar.layout', 'above' },
  { 'interface.toolbar.auto_hide_toolbar', 'always_show' },
  { 'interface.tab_behavior.fill', false },
  { 'interface.tabs.color', 'always' },
  { 'interface.tabs.shell_icon_theme', 'theme' },
  { 'interface.tabs.count', 3 },
  { 'interface.panes.density', 'comfortable' },
  { 'interface.panes.headers', 'on_hover' },
  { 'interface.pane_padding.color', 'off' },
  { 'interface.active_panes.active_border', false },
  { 'interface.active_panes.active_border_color', 'accent' },
  { 'interface.active_panes.active_border_opacity', 100 },
  { 'interface.active_panes.active_border_animation', 'fade' },
  { 'interface.active_panes.fade', 'both' },
  { 'interface.active_panes.inactive_window', true },
  { 'interface.splits_focus.focus_follows_mouse', false },
  { 'interface.animation.style', 'natural' },

  -- [[ Terminal ]]
  { 'terminal.typography.font', 'Maple Mono NF' },
  { 'terminal.typography.style', 'SemiBold' },
  { 'terminal.typography.size', 18.5 },
  -- Percent of the font's own line height added
  { 'terminal.typography.line_height', 25 },
  { 'terminal.cursor.force', false },
  { 'terminal.cursor.shaders', false },
  { 'terminal.cursor.shader', 'warp' },
  { 'terminal.selection.foreground', 'theme' },
  { 'terminal.selection.background', 'theme' },
  { 'terminal.selection.corners', true },
  { 'terminal.scrolling.smooth', false },
  { 'terminal.path_browser.recent_paths', false },
}
