# Changelog

Releases of the gilitos92/tinycast fork. Each one names the
[abue-ammar/tinycast](https://github.com/abue-ammar/tinycast) version it is based on; upstream's own
changes are in its [releases](https://github.com/abue-ammar/tinycast/releases).

## [Unreleased]

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
