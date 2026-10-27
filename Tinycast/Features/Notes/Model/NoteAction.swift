import Foundation

/// What a row of the ⌘K panel does; its chord does the same with the panel closed.
enum NoteAction: Sendable, Equatable {
    case createNote
    case browseNotes
    case goBack
    case goForward
    case findInNote
    case openNotesFolder
    case format(NoteEditAction)
    case toggleFormattingBar
    case moveToTopRight
    case closeWindow
    case deleteNote
}

/// A chord in layout-free terms, so the panel's keycaps and its key handling read one value.
struct NoteShortcut: Sendable, Hashable {
    struct Modifiers: OptionSet, Sendable, Hashable {
        let rawValue: Int
        static let control = Modifiers(rawValue: 1 << 0)
        static let option = Modifiers(rawValue: 1 << 1)
        static let shift = Modifiers(rawValue: 1 << 2)
        static let command = Modifiers(rawValue: 1 << 3)
    }

    /// Digits stay apart from letters: they match by key code, which no layout shifts.
    enum Key: Sendable, Hashable {
        case letter(Character)
        case digit(Int)
    }

    let modifiers: Modifiers
    let key: Key

    init(_ modifiers: Modifiers, _ key: Key) {
        self.modifiers = modifiers
        self.key = key
    }

    /// One keycap each, in the order macOS menus print them.
    var glyphs: [String] {
        let marks: [(Modifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        let keyGlyph =
            switch key {
            case .letter(let letter): letter.uppercased()
            case .digit(let digit): String(digit)
            }
        return marks.filter { modifiers.contains($0.0) }.map(\.1) + [keyGlyph]
    }

    var label: String { glyphs.joined() }
}

struct NoteActionItem: Sendable, Equatable {
    enum Section: Sendable, Equatable {
        case note
        case format
        case window
        case delete

        var title: String? { self == .format ? String(localized: "Format") : nil }
    }

    let action: NoteAction
    let title: String
    let symbol: String
    let shortcut: NoteShortcut?
    let section: Section

    var isDestructive: Bool { action == .deleteNote }
}

enum NoteActionCatalog {
    struct Context: Sendable, Equatable {
        var hasActiveNote: Bool
        var rendersMarkdown: Bool
        var showsFormattingBar: Bool
        var isFormattingBarExpanded: Bool
        var canGoBack = false
        var canGoForward = false
    }

    static let toggleActionPanel = NoteShortcut(.command, .letter("k"))

    static let createNote = NoteActionItem(
        action: .createNote, title: String(localized: "Create Note"), symbol: "plus",
        shortcut: NoteShortcut(.command, .letter("n")), section: .note)
    static let browseNotes = NoteActionItem(
        action: .browseNotes, title: String(localized: "Browse Notes"), symbol: "rectangle.stack",
        shortcut: NoteShortcut(.command, .letter("p")), section: .note)
    static let goBack = NoteActionItem(
        action: .goBack, title: String(localized: "Go Back"), symbol: "chevron.backward",
        shortcut: NoteShortcut(.command, .letter("[")), section: .note)
    static let goForward = NoteActionItem(
        action: .goForward, title: String(localized: "Go Forward"), symbol: "chevron.forward",
        shortcut: NoteShortcut(.command, .letter("]")), section: .note)
    static let findInNote = NoteActionItem(
        action: .findInNote, title: String(localized: "Find in Note"), symbol: "text.magnifyingglass",
        shortcut: NoteShortcut(.command, .letter("f")), section: .note)
    static let openNotesFolder = NoteActionItem(
        action: .openNotesFolder, title: String(localized: "Open Notes Folder"), symbol: "folder",
        shortcut: NoteShortcut(.command, .letter("o")), section: .note)

    static let headings = [
        format(
            .setHeading(level: 1), String(localized: "Heading 1"), "textformat.size.larger",
            [.command, .option], .digit(1)),
        format(
            .setHeading(level: 2), String(localized: "Heading 2"), "textformat.size", [.command, .option],
            .digit(2)),
        format(
            .setHeading(level: 3), String(localized: "Heading 3"), "textformat.size.smaller",
            [.command, .option], .digit(3)),
        format(.setHeading(level: 0), String(localized: "Text"), "textformat", [.command, .option], .digit(0))
    ]
    static let bold = format(.toggleInline(.bold), String(localized: "Bold"), "bold", .command, .letter("b"))
    static let italic = format(
        .toggleInline(.italic), String(localized: "Italic"), "italic", .command, .letter("i"))
    static let strikethrough = format(
        .toggleInline(.strikethrough), String(localized: "Strikethrough"), "strikethrough",
        [.command, .shift], .letter("x"))
    static let inlineCode = format(
        .toggleInline(.code), String(localized: "Inline Code"), "chevron.left.forwardslash.chevron.right",
        .command, .letter("e"))
    static let link = format(.toggleLink, String(localized: "Link"), "link", .command, .letter("l"))
    static let codeBlock = format(
        .toggleCodeBlock, String(localized: "Code Block"), "curlybraces", [.command, .option], .letter("c"))
    static let quote = format(
        .toggleQuote, String(localized: "Quote"), "text.quote", [.command, .shift], .letter("b"))
    static let numberedList = format(
        .toggleList(.ordered), String(localized: "Numbered List"), "list.number", [.command, .shift],
        .digit(7))
    static let bulletList = format(
        .toggleList(.bullet), String(localized: "Bullet List"), "list.bullet", [.command, .shift], .digit(8))
    static let taskList = format(
        .toggleList(.task), String(localized: "Task List"), "checklist", [.command, .shift], .digit(9))

    /// The editor's own chords, which it reads from here so a listed shortcut is the real one.
    static let formatItems =
        headings + [bold, italic, strikethrough, inlineCode, link, codeBlock, quote]
        + [numberedList, bulletList, taskList]

    static let moveToTopRight = NoteActionItem(
        action: .moveToTopRight, title: String(localized: "Move Window to Top Right"),
        symbol: "arrow.up.right.square",
        shortcut: nil, section: .window)
    static let closeWindow = NoteActionItem(
        action: .closeWindow, title: String(localized: "Close Window"), symbol: "xmark.square",
        shortcut: NoteShortcut(.command, .letter("w")), section: .window)
    static let deleteNote = NoteActionItem(
        action: .deleteNote, title: String(localized: "Delete Note"), symbol: "trash",
        shortcut: NoteShortcut(.control, .letter("x")), section: .delete)

    /// Every row the panel offers for this state, in display order.
    static func items(in context: Context) -> [NoteActionItem] {
        var items = [createNote, browseNotes]
        if context.canGoBack { items.append(goBack) }
        if context.canGoForward { items.append(goForward) }
        if context.hasActiveNote { items.append(findInNote) }
        items.append(openNotesFolder)
        if context.hasActiveNote, context.rendersMarkdown {
            items += formatItems
            if context.showsFormattingBar {
                items.append(
                    NoteActionItem(
                        action: .toggleFormattingBar,
                        title: context.isFormattingBarExpanded
                            ? String(localized: "Collapse Formatting Bar")
                            : String(localized: "Expand Formatting Bar"),
                        symbol: "paintbrush",
                        shortcut: NoteShortcut([.command, .option], .letter("t")), section: .format))
            }
        }
        items += [moveToTopRight, closeWindow]
        if context.hasActiveNote { items.append(deleteNote) }
        return items
    }

    /// Display order is kept: the panel's sections would scatter under a ranked order.
    static func matching(_ items: [NoteActionItem], query: String) -> [NoteActionItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        let needle = FuzzyMatch.Query(trimmed)
        return items.filter { FuzzyMatch.match(needle, candidate: $0.title) != nil }
    }

    static func item(for shortcut: NoteShortcut, in items: [NoteActionItem]) -> NoteActionItem? {
        items.first { $0.shortcut == shortcut }
    }

    private static func format(
        _ action: NoteEditAction, _ title: String, _ symbol: String,
        _ modifiers: NoteShortcut.Modifiers, _ key: NoteShortcut.Key
    ) -> NoteActionItem {
        NoteActionItem(
            action: .format(action), title: title, symbol: symbol,
            shortcut: NoteShortcut(modifiers, key), section: .format)
    }
}
