import SwiftUI

struct MenuSearchScreen: PaletteScreen {
    let session: MenuSearchSession
    let core: AppCore
    let vm: PaletteState
    let openActions: () -> Void

    var rows: [MenuSearchItem] { session.filtered }

    var primaryActionTitle: String { "Activate Menu Item" }

    private var coordinator: MenuSearchCoordinator { core.menuSearchCoordinator }

    private func item(at selection: Int) -> MenuSearchItem? {
        rows.indices.contains(selection) ? rows[selection] : nil
    }

    func hasActions(at selection: Int) -> Bool { item(at: selection) != nil }

    func actions(at selection: Int) -> PopoverMenuContent? {
        guard let item = item(at: selection) else { return nil }
        let pinned = coordinator.isPinned(item)
        let position = coordinator.pinPosition(of: item)
        var items = [
            PopoverMenuItem(
                title: primaryActionTitle, systemImage: "menubar.rectangle", shortcut: "↵"
            ) { coordinator.activate(item) },
            PopoverMenuItem(
                title: pinned ? "Unpin Menu Item" : "Pin Menu Item",
                systemImage: pinned ? "pin.slash" : "pin",
                startsSection: true, shortcut: "⌘."
            ) { coordinator.togglePin(item) },
        ]
        if let position {
            items.append(
                PopoverMenuItem(
                    title: "Move Up in Pinned", systemImage: "arrow.up",
                    isEnabled: position > 0, shortcut: "⌥⌘↑"
                ) { coordinator.movePin(item, by: -1) })
            items.append(
                PopoverMenuItem(
                    title: "Move Down in Pinned", systemImage: "arrow.down",
                    isEnabled: position < coordinator.visiblePinCount - 1, shortcut: "⌥⌘↓"
                ) { coordinator.movePin(item, by: 1) })
        }
        return PopoverMenuContent(header: item.title, items: items)
    }

    func perform(_ shortcut: PaletteShortcut, at selection: Int) -> Bool {
        guard shortcut == .pin, let item = item(at: selection) else { return false }
        coordinator.togglePin(item)
        return true
    }

    /// ⌥⌘↑/↓ on the selected row, when it is pinned.
    func movePin(_ delta: Int, at selection: Int) {
        guard let item = item(at: selection) else { return }
        coordinator.movePin(item, by: delta)
    }

    func activate(at selection: Int) {
        guard let item = item(at: selection) else { return }
        core.menuSearchCoordinator.activate(item)
    }

    func secondary(at selection: Int) -> Bool { false }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(content(selection: selection, scroll: scroll))
    }

    @ViewBuilder
    private func content(selection: Int, scroll: ScrollIntent) -> some View {
        switch session.target {
        case .searchable(let name):
            if session.state == .reading {
                EmptyResults(text: "Reading menu…")
            } else if rows.isEmpty {
                EmptyResults(text: "No menu items found in \(name)")
            } else {
                MenuSearchList(
                    items: rows, targetName: name, isSearching: session.isSearching,
                    pinnedCount: session.pinnedCount, pinnedIDs: Set(session.pinnedIDs),
                    iconURL: core.menuSearchCoordinator.frozenIconURL,
                    iconStamp: core.menuSearchCoordinator.frozenIconStamp,
                    selectedID: rows.indices.contains(selection) ? rows[selection].id : nil,
                    scroll: scroll,
                    onActivate: { core.menuSearchCoordinator.activate($0) })
            }
        case .excluded(let name):
            EmptyResults(text: "Menu search is turned off for \(name)")
        case .selfTarget:
            EmptyResults(text: "Tinycast has no menu to search")
        case .menuLess(let name):
            EmptyResults(text: "\(name) has no menu bar to search")
        case .noApplication:
            EmptyResults(text: "No application to search")
        }
    }
}
