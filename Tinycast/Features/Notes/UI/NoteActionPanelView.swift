import SwiftUI

/// The ⌘K panel, in `PopoverMenu`'s look; that view reads palette state that Notes does not have.
struct NoteActionPanelView: View {
    let onContentHeight: (CGFloat) -> Void
    @Environment(NotesCoordinator.self) private var notes
    @Environment(\.displayScale) private var displayScale
    @FocusState private var searchFocused: Bool

    private var surface: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.Radius.menuPanel, style: .continuous)
    }

    var body: some View {
        let items = notes.visibleActionItems
        VStack(spacing: 0) {
            list(items)
            hairline
            searchField
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .glassEffect(.regular, in: surface)
        .clipShape(surface)
        .onAppear(perform: focusSearch)
        .onChange(of: notes.actionPanelFocusRevision) { _, _ in focusSearch() }
        .onKeyPress(.downArrow) {
            notes.moveActionPanelSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            notes.moveActionPanelSelection(by: -1)
            return .handled
        }
        .onKeyPress(keys: [.return, KeyEquivalent("\u{3}")]) { _ in
            notes.performSelectedAction()
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Actions")
    }

    private var hairline: some View {
        Rectangle()
            .fill(Theme.Colors.separator)
            .frame(height: 1 / displayScale)
            .accessibilityHidden(true)
    }

    private var searchField: some View {
        @Bindable var notes = notes
        return TextField("", text: $notes.actionPanelQuery)
            .textFieldStyle(.plain)
            .font(Theme.Typography.menuRow)
            .foregroundStyle(Theme.Colors.textPrimary)
            .tint(Theme.Colors.textPrimary)
            .focused($searchFocused)
            .lineLimit(1)
            .background(alignment: .leading) {
                if notes.actionPanelQuery.isEmpty {
                    Text("Search for actions…")
                        .font(Theme.Typography.menuRow)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .onExitCommand { notes.closeActionPanel() }
            .padding(.horizontal, Theme.Spacing.xl)
            .frame(height: Theme.Size.noteSearchHeight)
            .accessibilityLabel("Search for actions")
    }

    @ViewBuilder
    private func list(_ items: [NoteActionItem]) -> some View {
        if items.isEmpty {
            Text("No Results")
                .font(Theme.Typography.menuRow)
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Size.menuRowHeight)
                .padding(Theme.Spacing.md)
                .measuredHeight(onContentHeight)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Size.menuRowSpacing) {
                        ForEach(items.indices, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 0) {
                                boundary(before: index, in: items)
                                NoteActionPanelRow(
                                    item: items[index],
                                    selected: index == notes.actionPanelSelection
                                ) {
                                    notes.perform(items[index].action)
                                }
                                .onContinuousHover {
                                    if case .active = $0 { notes.selectActionPanelItem(at: index) }
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .measuredHeight(onContentHeight)
                }
                .scrollIndicators(.never)
                .onChange(of: notes.actionPanelSelection) { _, selected in
                    proxy.scrollTo(selected)
                }
            }
        }
    }

    /// A hairline between sections, and the section's title when it has one.
    @ViewBuilder
    private func boundary(before index: Int, in items: [NoteActionItem]) -> some View {
        let section = items[index].section
        if index > 0, items[index - 1].section != section {
            hairline
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
        }
        if let title = section.title, index == 0 || items[index - 1].section != section {
            Text(title)
                .font(Theme.Typography.sectionHeader)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(height: Theme.Size.menuSectionHeader, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxs)
        }
    }

    private func focusSearch() {
        Task { @MainActor in
            await Task.yield()
            searchFocused = true
        }
    }
}

extension View {
    fileprivate func measuredHeight(_ report: @escaping (CGFloat) -> Void) -> some View {
        onGeometryChange(for: CGFloat.self) {
            $0.size.height
        } action: {
            report($0)
        }
    }
}

private struct NoteActionPanelRow: View {
    let item: NoteActionItem
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.symbol)
                    .font(
                        .system(
                            size: Theme.Typography.menuSymbolSize, weight: Theme.Typography.menuSymbolWeight)
                    )
                    .foregroundStyle(item.isDestructive ? Theme.Colors.destructive : Theme.Colors.menuSymbol)
                    .frame(width: Theme.Size.menuIcon, height: Theme.Size.menuIcon)
                Text(item.title)
                    .font(Theme.Typography.menuRow)
                    .foregroundStyle(item.isDestructive ? Theme.Colors.destructive : Color.primary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.sm)
                if let shortcut = item.shortcut {
                    HStack(spacing: Theme.Spacing.xxs) {
                        ForEach(shortcut.glyphs, id: \.self) { glyph in
                            KeyCapChip(text: glyph, style: .outline)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .frame(
                maxWidth: .infinity, minHeight: Theme.Size.menuRowHeight,
                maxHeight: Theme.Size.menuRowHeight, alignment: .leading
            )
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.menuRow, style: .continuous)
                    .fill(selected ? Theme.Colors.menuHover : Color.clear))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.shortcut?.label ?? "")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
