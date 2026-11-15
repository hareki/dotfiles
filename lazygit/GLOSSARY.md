# Lazygit config

A personal lazygit setup: its look, and codediff, the diff renderer it runs for every diff it draws, together with the tests that pin what codediff shows.

## Language

### Rendering

**Codediff**:
The diff renderer lazygit runs: it draws git's patch the way codediff.nvim draws it in the editor, with syntax colors and the changed words picked out.
_Avoid_: pager, custom pager

**Layout**:
One of the two ways a diff is drawn: inline, the deleted rows above the added ones, or side by side, the old file on the left.
_Avoid_: view, style

**Section**:
One file's part of a diff: its notes, and its hunks under their headers.
_Avoid_: file block, file diff

**Full mode**:
A section whose syntax colors come from the whole file on each side, so a row is colored as the editor colors that line.
_Avoid_: blob mode, full-content mode

**Fragment mode**:
A section whose syntax colors come from the rows of each hunk alone, because the file is not at hand, is too large, or disagrees with the patch.
_Avoid_: hunk mode, partial mode

**Plain section**:
A section past the size caps: its rows keep their tints and carry neither syntax colors nor changed words.
_Avoid_: tint-only, unhighlighted

**Degrade**:
To give a render less than full decoration because the content, the size or the clock is against it.
_Avoid_: fall back (the client's word)

**Record**:
A mark ahead of a rendered row saying which line of which file the row shows, which is what lets lazygit stage or edit the line under its cursor.
_Avoid_: metadata, annotation

### Tests

**Fixture**:
A diff as git wrote it, kept with its goldens.
_Avoid_: sample, test case

**Golden**:
The render a fixture must produce in one layout.
_Avoid_: snapshot (a tmux term), expected output

**Fixture repository**:
The blobs and worktree files a fixture's diff names, from which a throwaway repository is built for it to render in.
_Avoid_: test repo, repo fixture
