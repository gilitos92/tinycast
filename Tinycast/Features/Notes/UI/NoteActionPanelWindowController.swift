import AppKit
import SwiftUI

/// A child window hung from the note's bottom-right corner, so a 180pt note can still hold it.
@MainActor
final class NoteActionPanelWindowController: NSObject, NSWindowDelegate {
    private unowned let coordinator: NotesCoordinator
    private var panel: NotesPanel?
    private var height = Theme.Size.noteActionPanel.height

    init(coordinator: NotesCoordinator) {
        self.coordinator = coordinator
    }

    func show(over host: NSWindow) {
        let panel = ensurePanel()
        anchor(panel, over: host)
        if panel.parent !== host {
            panel.parent?.removeChildWindow(panel)
            host.addChildWindow(panel, ordered: .above)
        }
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
    }

    func hide() {
        guard let panel else { return }
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    // MARK: - NSWindowDelegate

    /// Closes like a popover; focus stays where the click landed.
    func windowDidResignKey(_ notification: Notification) {
        coordinator.closeActionPanel(focusEditor: false)
    }

    // MARK: - Private

    private func ensurePanel() -> NotesPanel {
        if let panel { return panel }
        let root = NoteActionPanelView { [weak self] in self?.resize(toContentHeight: $0) }
            .environment(coordinator)
        let hosting = NSHostingView(rootView: root)
        hosting.sizingOptions = []
        let panel = NotesPanel(
            content: hosting,
            size: Theme.Size.noteActionPanel,
            styleMask: .borderless,
            acceptsMain: false)
        panel.delegate = self
        panel.onEscape = { [weak coordinator] in coordinator?.closeActionPanel() }
        panel.onShortcut = { [weak coordinator] in
            coordinator?.handleActionPanelShortcut($0) ?? false
        }
        self.panel = panel
        return panel
    }

    /// The bottom edge holds and the panel grows up, kept inside the screen the note is on.
    private func anchor(_ panel: NotesPanel, over host: NSWindow) {
        let size = CGSize(width: Theme.Size.noteActionPanel.width, height: height)
        let inset = Theme.Spacing.md
        var origin = CGPoint(x: host.frame.maxX - inset - size.width, y: host.frame.minY + inset)
        if let visible = (host.screen ?? NSScreen.main)?.visibleFrame {
            origin.y = min(origin.y, visible.maxY - size.height)
            origin.x = max(origin.x, visible.minX)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: false)
    }

    private func resize(toContentHeight content: CGFloat) {
        let fitted = min(Theme.Size.noteActionPanel.height, Theme.Size.noteSearchHeight + content)
        guard abs(fitted - height) > 0.5 else { return }
        height = fitted
        guard let panel, let host = panel.parent else { return }
        anchor(panel, over: host)
        panel.invalidateShadow()
    }
}
