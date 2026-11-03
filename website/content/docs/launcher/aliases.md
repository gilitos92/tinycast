---
title: Aliases
description: Give any launcher entry a short name that comes first when you type it.
---

An alias is your own short name for a launcher entry. Type `ps` to get Photoshop, or `sh` to get the
shell script you run every morning.

Aliases work on **any** entry: apps, System Settings panes, commands, Quick Actions, quicklinks,
snippets, Apple Shortcuts, system actions, window commands, custom sizes, layouts, rooms and
extension commands.

## Setting one

Set aliases in **Settings**, in the alias field on the item's row. Every pane that lists launcher
items has this field, including Applications, System Settings, System Actions, Commands,
Quicklinks, Quick Actions and each feature's own command list. For extensions, the field is next to
each command's shortcut in **Settings → Extensions**.

Each entry can have one alias. The field has a button to clear it.

Aliases aren't in the <kbd>⌘</kbd><kbd>K</kbd> menu, because naming something is a one-time setting
rather than something you do in the middle of a search.

## How an alias ranks

- **Typing the whole alias exactly always puts that entry first**, no matter what you picked before
  or what else has that name.
- **Typing the start of an alias** ranks just above names that start the same way. Something you
  pick very often can still rank higher.
- A match in the **middle** of an alias ranks the same as the other names an app is known by.
- **Scattered letters never match an alias.** `ps` won't match an alias of `Pixelmator Studio` by
  skipping letters, because that would make short aliases useless.

The first rule matters most. A two-letter alias is only worth setting if it always comes first.

## Space jumps into a command's inputs

When a command takes inputs, like a quicklink, a custom command or an extension command, type the
start of its alias and press <kbd>space</kbd>. The cursor jumps to the first input, as in Raycast.

- It works with the start of the alias too: `tr` is enough for `translate`.
- It works only when what you typed is the start of the entry's alias. If you typed part of its
  name that isn't the start of its alias, <kbd>space</kbd> types a space.
- Everywhere else, <kbd>space</kbd> types a space as usual.

One alias can block another. If `go` leads the list and takes inputs, you can't type
`go` <kbd>space</kbd> `compose` to reach an alias `go compose`. Search for that entry by its name
instead.

## In the list

An entry with an alias shows it as a small tag after its name, so you can see which entries you've
named.

## Backups and cleanup

Aliases are included in [backups](/docs/reference/backup).

An alias is removed along with the thing it names. If you uninstall the app, delete the quicklink or
remove the extension, its alias is deleted too, so it can't linger and match nothing.

Raycast exports include an alias for each command. The
[importer](/docs/reference/import-from-raycast) brings over the aliases for apps.
