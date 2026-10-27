# Changelog

Releases of the gilitos92/tinycast fork. Each one names the
[abue-ammar/tinycast](https://github.com/abue-ammar/tinycast) version it is based on; upstream's own
changes are in its [releases](https://github.com/abue-ammar/tinycast/releases).

## [Unreleased]

### Added

- `⌘[` and `⌘]` go back and forward, as in Raycast: in Notes through the notes opened this session,
  and in Quick AI through the saved chats. Both appear in the ⌘K actions while there is somewhere to
  go.

## [1.4.0] - 2026-10-23

Based on upstream v0.12.2-beta.125.

### Added

- Upstream's changes since v0.11.22-beta.121, among them native localization in eight languages,
  editing Clipboard History text entries in place (⌘E), custom request headers for AI connections,
  optional Dictation sounds and a Show animations setting.

### Changed

- Extension OAuth sign-in uses upstream's own `state` fix, which replaces the fork's.
- The fork's own text is translated into upstream's eight languages: emoji renaming, menu item pins,
  Clipboard History's Quick Look and the Notes action panel.

### Fixed

- `Scripts/update-from-upstream.sh` drops a `.github/` file that upstream newly added instead of
  stopping on it.
- The test harnesses no longer leave an empty preferences file in `~/Library/Preferences` on every
  run.

## [1.3.0] - 2026-10-19

Based on upstream v0.11.22-beta.121.

### Added

- The emoji picker can rename an emoji or symbol. Rename Emoji… (⌘E, or in the Actions menu) sets a
  name of your own, shown in the footer and searched beside the original name. Reset Name, or an empty
  name, brings the original back. Names travel with the configuration backup.

### Fixed

- Typing right after closing a dialog over the palette goes to the search field again, instead of
  nowhere.
- While a Japanese or Chinese input method is composing in a dialog, Return and Escape go to the input
  method instead of confirming or cancelling the dialog.

## [1.2.1] - 2026-10-17

Based on upstream v0.11.22-beta.121.

### Fixed

- Opening Quick Look in Clipboard History with ⌘Y no longer closes the palette and the preview with
  it.

## [1.2.0] - 2026-10-17

Based on upstream v0.11.22-beta.121.

### Added

- Clipboard History has Quick Look. Press ⌘Y, or pick Quick Look in the Actions menu, to see the
  selected entry in the system Quick Look panel. The arrow keys move through the history while it
  stays open, and ⌘Y or Escape closes it.

## [1.1.3] - 2026-10-17

Based on upstream v0.11.22-beta.121.

### Fixed

- Snippets from the palette or a hotkey, keyword expansion, and dictation no longer end a Finder
  rename. Before, the rename finished early and the text was saved as a `.textClipping` file.

## [1.1.2] - 2026-10-17

Based on upstream v0.11.22-beta.121.

### Fixed

- Pasting from Clipboard History or the emoji picker while renaming a file in Finder puts the text in
  the name. Before, Finder finished the rename early and saved the paste as a `.textClipping` file.

## [1.1.1] - 2026-10-16

Based on upstream v0.11.22-beta.121.

### Added

- Releases are published on GitHub with a DMG to download, and the README explains how to install
  and open it. Installed copies update themselves from those releases.

## [1.1.0] - 2026-10-16

Based on upstream v0.11.22-beta.121.

### Added

- Notes has Raycast's action panel: ⌘K opens a searchable list of everything the note window can
  do, each with its shortcut.
- ⌃X moves the open note to Trash, or the selected note in the note list, after a confirmation.

### Changed

- Link in Notes moved from ⌘K to ⌘L, matching Raycast.

## [1.0.2] - 2026-10-15

Based on upstream v0.11.22-beta.121.

### Fixed

- Signing in to an extension through Raycast's OAuth web redirect (the GitHub extension, for one)
  no longer ends on an "Application error" page; the sign-in returns to Tinycast.

## [1.0.1] - 2026-10-15

Based on upstream v0.11.22-beta.121.

### Added

- A notice at the top of the README that this is a modified fork, as AGPL-3.0 section 5(a) asks.

## [1.0.0] - 2026-10-15

Based on upstream v0.11.22-beta.121.

### Fixed

- Pasting from Clipboard History, the emoji picker or File Search lands in the app the palette was
  opened over; before, keyboard focus stayed on the closed palette and nothing was pasted.
- A paste from a palette opened over a Tinycast note goes into the note.

### Added

- Emoji search ranks whole words in an emoji's name above keyword-only matches, drops scattered-letter
  matches once a real word matches (`kiss` → 😘, no flags), and puts emoji you picked before first,
  last used first.
- The emoji picker's footer shows the selected emoji's name.
- Search Menu Bar Items can pin items per app: `⌘.` pins or unpins, `⌥⌘↑/↓` reorders, and pins lead
  the list in a Pinned section.
- `Scripts/install-local.sh` builds and installs the fork; `Scripts/update-from-upstream.sh` merges
  upstream, tests, installs and pushes.

### Changed

- The in-app updater reads this fork's releases, so an upstream release never replaces this build.

### Removed

- Upstream's GitHub workflows, issue and pull request templates, funding link and CodeRabbit config.
