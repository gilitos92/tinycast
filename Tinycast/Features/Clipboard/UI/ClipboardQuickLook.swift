import AppKit
import QuickLookUI

/// ⌘Y hands the selected clip to the system Quick Look panel, the one Finder and Raycast use.
@MainActor
final class ClipboardQuickLookController: NSObject, PaletteQuickLookSource,
    @MainActor QLPreviewPanelDataSource
{
    private let store: ClipboardStore
    /// Text has no file of its own, so Quick Look reads a copy written here, deleted on close.
    private let textDirectory: URL
    private var preview: ClipPreviewItem?
    private var shownID: ClipboardItem.ID?
    private var writeTask: Task<Void, Never>?
    private var keyObserver: NotificationToken?
    private(set) var isShowing = false
    /// Quick Look makes itself key, and a text preview would then eat the arrows and Escape.
    var onTookKey: (() -> Void)?
    var onEnd: (() -> Void)?

    init(store: ClipboardStore, bundleID: String) {
        self.store = store
        textDirectory = FileManager.default.temporaryDirectory
            .appending(path: bundleID, directoryHint: .isDirectory)
            .appending(path: "QuickLook", directoryHint: .isDirectory)
    }

    func show(_ item: ClipboardItem) {
        isShowing = true
        load(item)
        guard let panel = QLPreviewPanel.shared() else { return }
        // Above the palette, which sits over every other app's panels.
        panel.level = .dialog
        let center = NotificationCenter.default
        keyObserver = NotificationToken(
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification, object: panel, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.onTookKey?() }
            },
            center: center)
        panel.orderFront(nil)
    }

    /// The panel's own `isKeyWindow` still reads false while the palette's resign is delivered.
    var holdsKey: Bool { NSApp.keyWindow is QLPreviewPanel }

    func follow(_ item: ClipboardItem?) {
        guard isShowing else { return }
        guard let item else { return hide() }
        guard item.id != shownID else { return }
        load(item)
    }

    func hide() {
        guard isShowing else { return }
        if QLPreviewPanel.sharedPreviewPanelExists() { QLPreviewPanel.shared()?.orderOut(nil) }
        quickLookDidEnd()
    }

    func beginControl(of panel: QLPreviewPanel) {
        panel.dataSource = self
    }

    func quickLookDidEnd() {
        guard isShowing else { return }
        isShowing = false
        keyObserver = nil
        writeTask?.cancel()
        writeTask = nil
        preview = nil
        shownID = nil
        let directory = textDirectory
        Task.detached(priority: .utility) { try? FileManager.default.removeItem(at: directory) }
        onEnd?()
    }

    private func load(_ item: ClipboardItem) {
        shownID = item.id
        writeTask?.cancel()
        writeTask = nil
        let title = ClipboardActionsMenu.headerText(item)
        guard item.kind == .text else {
            let url = store.imageURL(for: item) ?? store.fileURL(for: item)
            return present(ClipPreviewItem(url: url, title: title))
        }
        let file = textDirectory.appending(path: "\(item.id.uuidString).txt")
        let text = item.text ?? ""
        writeTask = Task {
            let written = await Self.write(text, to: file)
            guard !Task.isCancelled, isShowing, shownID == item.id else { return }
            present(ClipPreviewItem(url: written ? file : nil, title: title))
        }
    }

    @concurrent private static func write(_ text: String, to file: URL) async -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(text.utf8).write(to: file, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func present(_ item: ClipPreviewItem) {
        preview = item
        guard QLPreviewPanel.sharedPreviewPanelExists() else { return }
        QLPreviewPanel.shared()?.reloadData()
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        preview == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        preview
    }
}

/// Quick Look reads the URL and the title; a text clip's file name would say nothing.
private final class ClipPreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?

    init(url: URL?, title: String) {
        previewItemURL = url
        previewItemTitle = title
    }
}
