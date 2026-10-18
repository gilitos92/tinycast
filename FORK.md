# gilitos92/tinycast

A personal fork of [abue-ammar/tinycast](https://github.com/abue-ammar/tinycast).

## What differs from upstream

- **Clipboard History pastes again.** Closing the palette re-activates the app behind it
  (`activateReclaimingKeyboard`), so its ⌘V lands instead of going nowhere until a click. Opened over a
  Tinycast note, a paste goes to the note.
- **Pasting into a Finder rename works.** An app still active behind the palette takes ⌘V before the
  hand-back (`Paster.pastePasteboard(into:)`), so Finder no longer confirms the rename first and drops a
  `.textClipping` into the folder. Snippets and dictation (`TextInjector`) never re-activate an app
  that is still active either, and hand the keyboard back only after the text is in.
- **Emoji search ranks by whole words.** A complete word in an emoji's name outranks keyword-only hits,
  and scattered-letter matches drop out once a real word matches (`kiss` → 😘, no flags). An emoji you
  picked before leads whenever it matches as a word, last used first.
- **The emoji picker's footer names the selected emoji.**
- **Clipboard History has Quick Look.** `⌘Y` opens the selected entry in the system Quick Look
  panel, and the arrow keys move through the history while it stays open.
- **Search Menu Bar Items can pin items** per app: `⌘.` pins or unpins, `⌥⌘↑/↓` reorders, and pins lead
  the list in a Pinned section.
- **Extension OAuth sign-in completes.** Raycast's web redirect page needs `state` as base64url JSON,
  so `PKCEClient` sends it that way instead of random bytes.
- **Releases are built here and published by hand.** The in-app updater reads this fork's GitHub
  releases, so an upstream release never replaces this build. Pulling upstream's changes means running
  `Scripts/update-from-upstream.sh` (below).
- **No CI or community files.** `.github/` (release, website and bot workflows, issue forms) and
  `.coderabbit.yaml` are removed, and `docs/release.md` describes upstream's process only.

## Install

Needs Xcode, XcodeGen (`brew install xcodegen`) and the `Tinycast Self-Signed` identity
([docs/signing.md](docs/signing.md) §1; with OpenSSL 3, add `-legacy` to the `openssl pkcs12` command).

```sh
./Scripts/install-local.sh
```

It builds a Release app outside this iCloud-synced folder, stamps it with the fork's version, quits
Tinycast, replaces `/Applications/Tinycast.app`
and relaunches it. Settings, history, notes and pins live in `~/Library` and survive. The signing
identity stays the same, so Accessibility stays granted; recreating the identity means removing and
re-adding Tinycast under System Settings › Privacy & Security › Accessibility once.

## Versions and releases

The fork keeps its own version line, independent of upstream's: `MARKETING_VERSION` in `project.yml`
is the version the About window shows, and `install-local.sh` stamps it with the commit count as the
build number.

Local tags are `fork-vX.Y.Z`: this clone also fetches upstream's `v*` tags, and a shared name would
collide. The published GitHub release is tagged `vX.Y.Z`, because that is the only shape the updater
parses; GitHub creates that tag, and it stays clear of upstream while the fork's line runs ahead of
upstream's 0.x. Each [CHANGELOG.md](CHANGELOG.md) entry names the upstream version it is based on.

To release, follow the release workflow: on a `Release-X.Y.Z` branch from `development`, move the
changelog's Unreleased entries under the new version, bump `MARKETING_VERSION` (then `xcodegen
generate`), merge `--no-ff` into `main` and `development`, tag `fork-vX.Y.Z` on `main`, push both
branches and the tag, and install from `main` with `./Scripts/install-local.sh`. Then publish it:

```sh
./Scripts/publish-release.sh
```

It takes the version from `project.yml`, or as an argument, and refuses to run until
`fork-v<version>` is pushed. It checks that tag out in a temporary worktree, so any branch works,
builds it signed with `Tinycast Self-Signed` and runs `verify-signature.sh`. It then packs
`Tinycast-<version>.zip` for the updater and `Tinycast-<version>.dmg` for people, and publishes both
as release `v<version>` with that version's changelog section as the notes. The build is not notarized, so a downloaded copy
needs Gatekeeper's one-time approval; the [README](README.md#install-this-fork) walks through it. The
updater only installs a build signed by the identity the running copy carries, so every published
release must be built on a Mac holding this same `Tinycast Self-Signed` key.

## Branches

- `development` is where every change lands, fork patches and upstream merges alike.
- `main` only moves by merging `development` into it with `--no-ff`, once a build has been used a while.
- `upstream/main` is abue-ammar/tinycast; nothing is ever pushed there.

## Update from upstream

```sh
git switch development
./Scripts/update-from-upstream.sh
```

The script:

1. Refuses to run off `development` or with uncommitted changes.
2. Fetches `upstream` and stops if there is nothing new.
3. Merges `upstream/main` with `--no-ff`. Upstream edits to files the fork deleted (`.github/`,
   `.coderabbit.yaml`) are dropped automatically.
4. Regenerates `Tinycast.xcodeproj` with XcodeGen, so files upstream added or removed are built.
5. Runs `./Scripts/run-tests.sh`, then `./Scripts/install-local.sh`, then pushes `development`.

### When the merge stops on a conflict

Any other conflict means upstream changed code a fork patch also changed. The script lists the files
and stops. Resolve each one keeping both intents, then:

```sh
git add <files>
git commit --no-edit
./Scripts/update-from-upstream.sh --finish
```

`--finish` skips the merge and runs steps 4–5. The fork patches live in these files, so a conflict
there is expected and the fork's side must survive:

| Patch | Files |
| --- | --- |
| Keyboard hand-back | `Platform/KeyboardHandoff.swift`, `Clipboard/Service/Paster.swift`, `Palette/PaletteWindowController.swift`, `Palette/PaletteCoordinator.swift`, `Extensions/Service/ExtensionHostBridge.swift`, `TextInjection/Service/TextInjector.swift`, every `activateReclaimingKeyboard()` caller |
| Emoji ranking | `Emoji/Service/EmojiIndex.swift`, `Emoji/Service/FrequentEmojiStore.swift` |
| Emoji name | `Palette/PaletteScreen.swift` (`footerCaption`), `Palette/RootPaletteView.swift` (`bottomBar`), `Emoji/UI/EmojiScreen.swift` |
| Menu pins | `MenuSearch/**`, `App/AppCore.swift` (`pinnedMenuItems`), `Palette/RootPaletteView.swift` (`movePinnedOrFavorite`) |
| OAuth state | `Scripts/raycast-runtime/src/api/oauth.js` (rebuild the runtime after a conflict) |
| Fork setup | `Updates/Model/ReleaseFeed.swift` (`repository`), `Scripts/install-local.sh`, `Scripts/publish-release.sh`, `Scripts/update-from-upstream.sh`, `Scripts/run-tests.sh` (harness file lists) |

Paths are under `Tinycast/Features/` unless they start with `Platform/`, `Palette/`, `App/` or
`Scripts/`. If upstream later ships its own fix for one of these, prefer upstream's and drop the patch.

### Check that it worked

The tests cover emoji ranking and menu pins. Paste focus is only checked by hand: copy something, open a
text field in any app, paste from Clipboard History, then repeat from inside a Tinycast note. Last,
start renaming a file in Finder and paste an emoji, then a snippet from the palette: each must land in
the name, which stays editable.
