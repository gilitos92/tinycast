import AppKit

/// Owns emoji delivery: frequency tallies the base glyph, the configured tone applies at copy time.
@MainActor
final class EmojiCoordinator {
    private let frequentEmoji: FrequentEmojiStore
    private let names: EmojiNameStore
    private let settings: AppSettings
    private let windowController: PaletteWindowController
    private let paletteCoordinator: PaletteCoordinator
    private unowned let core: AppCore

    init(
        frequentEmoji: FrequentEmojiStore,
        names: EmojiNameStore,
        settings: AppSettings,
        windowController: PaletteWindowController,
        paletteCoordinator: PaletteCoordinator,
        core: AppCore
    ) {
        self.frequentEmoji = frequentEmoji
        self.names = names
        self.settings = settings
        self.windowController = windowController
        self.paletteCoordinator = paletteCoordinator
        self.core = core
    }

    func displayName(of entry: EmojiEntry) -> String {
        names.name(for: entry.glyph) ?? entry.displayName
    }

    func rename(_ entry: EmojiEntry) async {
        guard
            let name = await core.requestText(
                title: "Rename \(entry.display(tone: settings.emojiSkinTone))",
                message: "Leave it empty to use “\(entry.displayName)”.",
                symbol: nil, text: names.name(for: entry.glyph) ?? "",
                placeholder: entry.displayName, confirmTitle: "Rename",
                maxLength: EmojiNameStore.maxLength)
        else { return }
        names.setName(name, for: entry.glyph)
    }

    func resetName(_ entry: EmojiEntry) {
        names.setName("", for: entry.glyph)
    }

    func pasteEmoji(_ entry: EmojiEntry) {
        frequentEmoji.record(entry.glyph)
        let previous = paletteCoordinator.hidePaletteForPaste()
        Paster.pasteString(entry.display(tone: settings.emojiSkinTone), previousApp: previous)
    }

    func copyEmoji(_ entry: EmojiEntry) {
        frequentEmoji.record(entry.glyph)
        paletteCoordinator.hidePalette(restoreFocus: false)
        Paster.copyString(entry.display(tone: settings.emojiSkinTone))
    }

    func pasteEmojiKeepingWindowOpen(_ entry: EmojiEntry) {
        frequentEmoji.record(entry.glyph)
        windowController.pasteStringKeepingWindowOpen(entry.display(tone: settings.emojiSkinTone))
    }
}
