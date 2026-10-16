# gilitos92/tinycast

A personal fork of [abue-ammar/tinycast](https://github.com/abue-ammar/tinycast).

## What differs from upstream

- **Clipboard History pastes again.** Closing the palette re-activates the app behind it
  (`activateReclaimingKeyboard`), so its ⌘V lands instead of going nowhere until a click.
- **Emoji search ranks by whole words.** A complete word in an emoji's name outranks keyword-only hits,
  and scattered-letter matches drop out once a real word matches (`kiss` → 😘, no flags). An emoji you
  picked before leads whenever it matches as a word, last used first.
- **The emoji picker's footer names the selected emoji.**
- **Search Menu Bar Items can pin items** per app: `⌘.` pins or unpins, `⌥⌘↑/↓` reorders, and pins lead
  the list in a Pinned section.
- **The in-app updater reads this fork's releases**, so an upstream release never replaces this build.
- **No CI, releases or community files.** This build is personal: `.github/` (release, website and bot
  workflows, issue forms) and `.coderabbit.yaml` are removed, and `docs/release.md` describes upstream's
  process only. Install with the script below.

## Install or update

Needs Xcode and the `Tinycast Self-Signed` identity ([docs/signing.md](docs/signing.md) §1; with
OpenSSL 3, add `-legacy` to the `openssl pkcs12` command).

```sh
./Scripts/install-local.sh
```

## Pull in upstream changes

Work happens on `development`; `main` only moves when `development` is merged into it.

```sh
git fetch upstream --tags
git merge --no-ff upstream/main
# If upstream touched a removed file, keep it removed: git rm -r .github .coderabbit.yaml
./Scripts/run-tests.sh && ./Scripts/install-local.sh
```
