import SwiftUI

struct NoteFormattingBar: View {
    @Environment(NotesCoordinator.self) private var notes

    private struct Control: Sendable {
        let item: NoteActionItem
        let isLit: @Sendable (NoteFormatting) -> Bool

        init(_ item: NoteActionItem, isLit: @escaping @Sendable (NoteFormatting) -> Bool) {
            self.item = item
            self.isLit = isLit
        }
    }

    private static let styles = [
        Control(NoteActionCatalog.bold) { $0.inlineStyles.contains(.bold) },
        Control(NoteActionCatalog.italic) { $0.inlineStyles.contains(.italic) },
        Control(NoteActionCatalog.strikethrough) { $0.inlineStyles.contains(.strikethrough) },
        Control(NoteActionCatalog.inlineCode) { $0.inlineStyles.contains(.code) },
        Control(NoteActionCatalog.link) { $0.isLink }
    ]

    private static let blocks = [
        Control(NoteActionCatalog.codeBlock) { $0.isCodeBlock },
        Control(NoteActionCatalog.quote) { $0.isQuote }
    ]

    private static let lists = [
        Control(NoteActionCatalog.numberedList) { $0.list == .ordered },
        Control(NoteActionCatalog.bulletList) { $0.list == .bullet },
        Control(NoteActionCatalog.taskList) { $0.list == .task }
    ]

    var body: some View {
        let formatting = notes.formatting
        let isExpanded = notes.isFormattingBarExpanded
        HStack(spacing: Theme.Spacing.sm) {
            if isExpanded {
                HStack(spacing: Theme.Spacing.sm) {
                    NoteHeadingButton(
                        level: formatting.headingLevel, isOpen: notes.isHeadingMenuPresented,
                        action: notes.toggleHeadingMenu
                    ) { notes.headingButtonFrame = $0 }
                    group(Self.styles, formatting)
                    group(Self.blocks, formatting)
                    group(Self.lists, formatting)
                }
                // Grows out of the round button; nothing leaves the capsule, so no clip is needed.
                .transition(.scale(scale: 0.6, anchor: .trailing).combined(with: .opacity))
            }
            NoteFormattingToggle(isExpanded: isExpanded, action: notes.toggleFormattingBar)
                // Drawn above the buttons, so they grow out from behind it.
                .zIndex(1)
        }
        .padding(Theme.Spacing.xs)
        // Behind the buttons, not around them: glass clips content, tooltips draw outside it.
        .background { Capsule().fill(Color.clear).frosted(in: Capsule()) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Formatting")
    }

    private func group(_ controls: [Control], _ formatting: NoteFormatting) -> some View {
        HStack(spacing: Theme.Spacing.xxs) {
            ForEach(controls, id: \.item.title) { control in
                let item = control.item
                let lit = control.isLit(formatting)
                BarButton(isSelected: lit, isCompact: true, action: { notes.perform(item.action) }) {
                    NoteBarGlyph(name: item.symbol)
                }
                .focusable(false)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(lit ? .isSelected : [])
                .tooltip("\(item.title)  \(item.shortcut?.label ?? "")")
            }
        }
    }
}

private struct NoteFormattingToggle: View {
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        BarButton(isSelected: isExpanded, isCompact: true, action: action) {
            NoteBarGlyph(name: "paintbrush")
        }
        .focusable(false)
        .accessibilityLabel("Formatting")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        // Against the window's trailing edge, so a centred label would run off it.
        .tooltip(String(localized: "Formatting  ⌥⌘T"), alignment: .trailing)
    }
}

/// Symbols differ in width, so a fixed frame keeps every button the same square.
private struct NoteBarGlyph: View {
    let name: String

    var body: some View {
        SymbolImage(name: name, size: Theme.Size.noteGlyph)
            .frame(width: Theme.Size.noteGlyph, height: Theme.Size.noteGlyph)
    }
}

private struct NoteHeadingButton: View {
    let level: Int?
    let isOpen: Bool
    let action: () -> Void
    let onFrameChange: (CGRect) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isHeading: Bool { (1...6).contains(level ?? 0) }

    var body: some View {
        BarButton(isSelected: isHeading || isOpen, isCompact: true, action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                NoteBarGlyph(name: "textformat.size")
                // Rotates rather than swaps, so opening the menu cannot shift the bar.
                Image(systemName: "chevron.down")
                    .font(Theme.Typography.disclosure)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .animation(reduceMotion ? nil : Theme.MenuMotion.chevronAnimation, value: isOpen)
            }
        }
        // Its menu hangs off this frame, which only the laid-out view knows.
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: {
            onFrameChange($0)
        }
        .focusable(false)
        .accessibilityLabel("Heading")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isHeading ? .isSelected : [])
        // The leading end of an expanded capsule, which a narrow note pushes against the edge.
        .tooltip(isOpen ? nil : String(localized: "Heading"), alignment: .leading)
    }

    private var accessibilityValue: String {
        switch level {
        case nil: ""
        case 0: String(localized: "Text")
        case let level?: String(localized: "Heading \(level)")
        }
    }
}
