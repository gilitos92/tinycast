import AppKit

@MainActor
final class MenuSearchCoordinator {
    private let settings: AppSettings
    private let appIndex: AppIndex
    private let session: MenuSearchSession
    private let pins: PinnedMenuItemStore
    private let palette: PaletteState
    private let paletteCoordinator: PaletteCoordinator
    private unowned let core: AppCore
    /// The app the open snapshot belongs to; activation re-resolves against this, never a retarget.
    private var frozenApp: NSRunningApplication?
    /// One decode shared by every row; resolved once per show so the list never re-hits icons.
    private(set) var frozenIconURL: URL?
    private(set) var frozenIconStamp: Int = 0

    init(
        settings: AppSettings, appIndex: AppIndex, session: MenuSearchSession,
        pins: PinnedMenuItemStore, palette: PaletteState, paletteCoordinator: PaletteCoordinator,
        core: AppCore
    ) {
        self.settings = settings
        self.appIndex = appIndex
        self.session = session
        self.pins = pins
        self.palette = palette
        self.paletteCoordinator = paletteCoordinator
        self.core = core
    }

    func applyEnabled() {
        appIndex.setCommandsVisible([.searchMenuItems], settings.navigationEnabled)
        guard !settings.navigationEnabled else { return }
        session.reset()
        if palette.mode == .menuSearch { palette.prepare(mode: .launcher) }
    }

    func show() {
        guard settings.navigationEnabled else { return }
        guard Permissions.ensureAccessibility() else {
            Task { await self.reportPermissionFailure() }
            return
        }
        paletteCoordinator.togglePalette(mode: .menuSearch)
    }

    /// Every open walks anew, a restore included: hiding dropped the last snapshot.
    func load() {
        guard Permissions.ensureAccessibility() else {
            Task { await self.reportPermissionFailure() }
            return
        }
        let app = paletteCoordinator.targetApp
        frozenApp = app
        session.setPinned(pins.pins(for: app?.bundleIdentifier))
        if let url = app?.bundleURL {
            frozenIconURL = url
            frozenIconStamp = FileIconStamp.value(for: url)
        } else {
            frozenIconURL = nil
            frozenIconStamp = 0
        }
        let target = MenuSearchTarget.classify(
            appName: app?.localizedName,
            isSelf: app?.bundleIdentifier == Bundle.main.bundleIdentifier,
            hasMenuBar: app?.activationPolicy == .regular,
            isExcluded: app?.bundleIdentifier
                .map(settings.menuSearchDisabledApps.contains) ?? false)
        switch target {
        case .searchable:
            if let app {
                session.startWalk(
                    target: target, pid: app.processIdentifier,
                    showsAppleMenu: settings.menuSearchShowsAppleMenu)
            } else {
                session.present(target: .noApplication, snapshot: [])
            }
        case .excluded, .selfTarget, .menuLess, .noApplication:
            session.present(target: target, snapshot: [])
        }
    }

    func activate(_ item: MenuSearchItem) {
        guard Permissions.ensureAccessibility() else {
            Task { await self.reportPermissionFailure() }
            return
        }
        guard let app = frozenApp, !app.isTerminated else {
            Task { await self.reportGone(targetName: session.targetName) }
            return
        }
        paletteCoordinator.hidePalette(restoreFocus: false)
        app.activateReclaimingKeyboard()
        let application = AXMenuAccess.application(for: app.processIdentifier)
        guard
            let leaf = AXMenuAccess.resolveLeaf(
                in: application, path: item.parentComponents, title: item.title),
            AXMenuAccess.isActionable(leaf),
            AXMenuAccess.press(leaf)
        else {
            Task { await self.reportPressFailure(item: item) }
            return
        }
    }

    func isPinned(_ item: MenuSearchItem) -> Bool {
        session.pinnedIDs.contains(item.id)
    }

    /// The position among the pins the open menu shows, which is what ⌥⌘↑/↓ walks.
    func pinPosition(of item: MenuSearchItem) -> Int? {
        session.isSearching ? nil : session.filtered.prefix(session.pinnedCount).firstIndex(of: item)
    }

    var visiblePinCount: Int { session.pinnedCount }

    func togglePin(_ item: MenuSearchItem) {
        guard let bundleID = frozenApp?.bundleIdentifier else { return }
        pins.toggle(item.id, for: bundleID)
        session.setPinned(pins.pins(for: bundleID))
        follow(item)
    }

    func movePin(_ item: MenuSearchItem, by delta: Int) {
        guard let bundleID = frozenApp?.bundleIdentifier, pinPosition(of: item) != nil else { return }
        let visible = session.filtered.prefix(session.pinnedCount).map(\.id)
        pins.move(item.id, by: delta, among: visible, for: bundleID)
        session.setPinned(pins.pins(for: bundleID))
        follow(item)
    }

    /// Pinning moves the row, so the highlight goes with it instead of landing on a neighbour.
    private func follow(_ item: MenuSearchItem) {
        guard let index = session.filtered.firstIndex(of: item) else { return }
        palette.selection = index
    }

    // MARK: - Reporting

    private func reportPermissionFailure() async {
        let openSettings = await core.reportFailure(
            title: String(localized: "Tinycast Needs Accessibility Access"),
            message: String(localized: "Searching menus reads the front app's menu bar."),
            symbol: "menubar.rectangle", recovery: String(localized: "Open Settings"))
        if openSettings { Permissions.openAccessibilitySettings() }
    }

    private func reportGone(targetName: String?) async {
        await core.showNotice(
            title: String(localized: "Couldn't Activate Menu Item"),
            message: targetName.map { String(localized: "\($0) is no longer running.") }
                ?? String(localized: "The application is no longer running."),
            symbol: "menubar.rectangle", tone: .danger)
    }

    private func reportPressFailure(item: MenuSearchItem) async {
        await core.showNotice(
            title: String(localized: "Couldn't Activate “\(item.title)”"),
            message: String(localized: "Its menu changed before the press landed. Search again and retry."),
            symbol: "menubar.rectangle", tone: .danger)
    }
}
