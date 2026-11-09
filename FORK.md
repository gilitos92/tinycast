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
- **Emoji can be renamed.** `⌘E` gives an emoji a custom name (`EmojiNameStore`), shown in the footer
  and searched beside the catalog name.
- **Emoji search with AI.** In the emoji picker, Tab finds emoji by meaning with Apple Intelligence
  (`EmojiAISearchSession`), and a search nothing matches asks it on its own.
- **Clipboard History has Quick Look.** `⌘Y` opens the selected entry in the system Quick Look
  panel, and the arrow keys move through the history while it stays open.
- **Notes has Raycast's ⌘K action panel.** It lists every note action with its shortcut, and `⌃X`
  deletes the note. Link moves from `⌘K` to `⌘L`.
- **Notes and Quick AI go back and forward with `⌘[` and `⌘]`**, as in Raycast. Notes walks the notes
  opened this session; Quick AI steps through the saved chats.
- **Search Menu Bar Items can pin items** per app: `⌘.` pins or unpins, `⌥⌘↑/↓` reorders, and pins lead
  the list in a Pinned section.
- **Space after an alias acts like Raycast's.** It jumps into a command's inputs from the start of
  its alias, and runs a command without inputs once the whole alias is typed (`AliasSpacePolicy`).
- **Links from outside show everything before they run.** An extension command link (`raycast://`,
  `com.raycast:`) asks first, like a built-in one. The consent question shows the link's whole input
  in a scrolling box instead of cutting it at 160 characters, with hidden characters spelled out, and
  its run answers wait until the box is read to its end. A snippet list from a link shows each
  keyword and text. An extension that opens another extension's link asks too. Drop these once
  upstream asks and shows input the same way.
- **Releases come from the fork's own workflow,** signed with the fork's Developer ID and its own
  update key ([docs/signing.md](docs/signing.md)). The in-app updater reads this fork's GitHub
  releases, so an upstream release never replaces this build. Pulling upstream's changes means running
  `Scripts/update-from-upstream.sh` (below).
- **No upstream CI or community files.** `.github/` holds only the fork's `release.yml`; upstream's
  website and bot workflows, issue forms and `.coderabbit.yaml` are removed, and `docs/release.md`
  describes upstream's process only.

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
gh workflow run release.yml --repo gilitos92/tinycast --ref main
```

The **Release** workflow takes the version from `project.yml` and refuses to run unless
`fork-v<version>` points at `main`. On GitHub's `xcode-27` runner it builds that commit, signs it
with the fork's Developer ID, notarizes and staples the DMG, signs the updater zip with the release
key, and checks that the last release can install it. It then publishes release `v<version>` with
`Tinycast-<version>.dmg`, `Tinycast-<version>.zip` and its `.sig`, and that version's changelog
section as the notes.

1.11.0 is the bridge to Developer ID: 1.10.0 and older only install a build signed with
`Tinycast Self-Signed`, so 1.11.0 is still published by hand with `./Scripts/publish-release.sh`,
which builds it with that identity, and it already trusts the release key the workflow signs with.

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
3. Merges `upstream/main` with `--no-ff`. `.github/` and `.coderabbit.yaml` are restored to the
   fork's own version, so upstream's workflows and their edits never land.
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
| Emoji name | `Palette/PaletteScreen.swift` (`footerCaption`), `Palette/RootPaletteView.swift` (`bottomBar`), `Emoji/UI/EmojiScreen.swift`, `Emoji/Service/EmojiNameStore.swift`, `Windows/Dialog/DialogTextInput.swift` |
| Emoji AI search | `Emoji/Service/EmojiAISearchSession.swift`, `Emoji/UI/EmojiScreen.swift` (`tab`), `Emoji/UI/EmojiGridView.swift` (`aiResults`), `Emoji/Model/EmojiCatalog.swift` (`catalogGlyphs`), `Palette/RootPaletteView.swift` (`emojiAITabHint`) |
| Notes action panel | `Notes/Model/NoteAction.swift` (`NoteActionCatalog`, the only list of note actions), `Notes/UI/**` |
| Clipboard Quick Look | `Clipboard/UI/ClipboardQuickLook.swift`, `Clipboard/UI/ClipboardCoordinator.swift`, `Clipboard/UI/ClipboardScreen.swift`, `Palette/PalettePanel.swift` |
| Menu pins | `MenuSearch/**`, `App/AppCore.swift` (`pinnedMenuItems`), `Palette/RootPaletteView.swift` (`movePinnedOrFavorite`) |
| Link consent | `DeepLinks/UI/DeepLinkCoordinator.swift` (`runExtensionLink`, `askConsent`, `extensionConsentName`), `DeepLinks/Model/DeepLinkConsentPolicy.swift` (`key(entryID:percentEncodedQuery:)`), `DeepLinks/Model/DeepLinkInput.swift` (`details`), `Extensions/UI/ExtensionCoordinator.swift` (`runDeepLink`), `App/AppCore.swift` (`handleOpenURL`, `openChosenExtensionLink`, `confirm`, `choose`), `Quicklinks/UI/QuicklinkCoordinator.swift` (`performQuicklinkOpen`, `importQuicklinks(offered:)`, `reviewLines`), `Extensions/Model/ExtensionDeepLink.swift` (`field(named:)`, `reviewLines`, `keepingArguments`, `repeatsField`), `Extensions/Service/ExtensionManager.swift` (`launch(_:percentEncodedQuery:from:)`), `Extensions/Service/ExtensionHostBridge.swift` (`openRaycastURL`), `Extensions/Service/ExtensionMenuBarHost.swift`, `Platform/VisibleText.swift`, `Windows/Dialog/` (`.details`, `DialogDetailsField`, `allows`), `Snippets/Model/SnippetLinkReview.swift`, `Snippets/UI/SnippetCoordinator.swift` (`importSnippets`), `Scripts/run-tests.sh` and `Tests/quicklink-coordinator-test.swift` (`VisibleText`, `openChosenExtensionLink`, `confirm`) |
| Fork setup | `Updates/Model/ReleaseFeed.swift` (`repository`), `Info.plist` (`TinycastUpdatePublicKey`), `Palette/RootPaletteView.swift` (Changelog link), `.github/workflows/release.yml`, `Scripts/install-local.sh`, `Scripts/publish-release.sh`, `Scripts/update-from-upstream.sh`, `Scripts/check-migrations.sh` (`not_upstream`), `Scripts/run-tests.sh` (harness file lists), every harness's `UserDefaults` suite (a fixed name via `isolatedDefaults`, never a UUID) |

Paths are under `Tinycast/Features/` unless they start with `Platform/`, `Palette/`, `App/`,
`Windows/` or `Scripts/`. If upstream later ships its own fix for one of these, prefer upstream's and drop the patch.

### Check that it worked

The tests cover emoji ranking and menu pins. Paste focus is only checked by hand: copy something, open a
text field in any app, paste from Clipboard History, then repeat from inside a Tinycast note. Last,
start renaming a file in Finder and paste an emoji, then a snippet from the palette: each must land in
the name, which stays editable.
