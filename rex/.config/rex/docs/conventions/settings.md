# Settings

How the app's settings are recorded and applied, and how the theme gets in.

## The record

Rex.app keeps its settings in macOS preferences (`com.superlogical.rex`), which no file sets. `config/settings.lua` records them as `{ '<name>', value }` pairs, each the `client.setting.<name>` action and its `value`, and `apply_settings` (`features/settings-sync.lua`) sets them all. A setting changed in the Settings window is lost at the next apply, so a settings change is an edit to the record.

- Group the entries under `-- [[ Name ]]` headers named for the Settings window section that holds them
- Take a setting's name and its values from the Rex docs page [`/rex/docs/reference/mac-settings`](https://www.superlogical.com/rex/docs/reference/mac-settings). `rex -C <client label> actions --json` gives each enum, and `rex client list` the app's label
- `notifications.activity.sound_volume` stays out of the record: how its `value` maps to the stored `programActivitySoundVolume` is unknown

## Stored values

Read the stored values with `defaults read com.superlogical.rex`, never the plist file, which lags by seconds. Their keys carry a `Workspace.` prefix and differ from the setting names:

- `interfaceStyle` holds style and tint together: classic + tint is `useTheme`, classic `system`, glass + tint `blendTheme`, glass `modern`
- `terminalPaddingColor` off/automatic/always is `background`/`extend`/`extend-always`
- line height keeps the action's percent (`terminalCellHeightPercent`), while border opacity (`activePaneBorderOpacity`) reads `1` for the record's `100`. The docs give no range, so the action either scales the percent or clamps it at 1

## Theme

`client.theme.import` replaces the theme of the imported file's name in place, so `apply_settings` imports `themes/Catppuccin Mocha` on every run, and `themes.dark.palette` names it. Renaming the file renames the theme: change both. `apply_settings` reads the file at the stowed path, `~/.config/rex/themes/Catppuccin Mocha`, so it works only once stowed.

Outside this config, nvim's `config/filetypes/init.lua` opens `rex/themes/*` with the `ghostty` filetype.

## Font

Rex sets the face of regular text only (`terminal.typography.style`), and takes bold, italic and bold italic from the family's own faces. So the record names `Maple Mono NF Rex`, a family of four faces that holds Maple Mono NF's SemiBold and ExtraBold, with their italics, as its Regular and Bold. `scripts/build-maple-mono-nf-rex.py` builds it from the installed Maple Mono NF into `~/Library/Fonts`, changing only the names and the style flags. Run it again after updating Maple Mono NF.
