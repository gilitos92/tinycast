import Foundation

/// Menu items pinned per app, keyed by bundle ID, each in the order the user set.
@MainActor
@Observable
final class PinnedMenuItemStore {
    /// Only bounds a malformed or hand-edited file; nobody pins this many items in one app.
    private static let capPerApp = 500

    private let fileURL: URL
    private(set) var pinsByApp: [String: [MenuSearchItem.ID]]
    @ObservationIgnored var onPersistenceFailure: (() -> Void)?

    init(
        fileURL: URL = AppPaths.applicationSupport()
            .appendingPathComponent("menu-search-pinned.json")
    ) {
        self.fileURL = fileURL
        let decoded =
            (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: [String]].self, from: $0) } ?? [:]
        pinsByApp = decoded.compactMapValues { ids in
            let normalized = Self.normalized(ids)
            return normalized.isEmpty ? nil : normalized
        }
    }

    func pins(for bundleID: String?) -> [MenuSearchItem.ID] {
        bundleID.flatMap { pinsByApp[$0] } ?? []
    }

    func toggle(_ id: MenuSearchItem.ID, for bundleID: String) {
        var ids = pinsByApp[bundleID] ?? []
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
        pinsByApp[bundleID] = ids.isEmpty ? nil : ids
        persist()
    }

    /// `visible` is the pins the open menu shows, so a move never swaps with an unbuilt submenu's.
    func move(
        _ id: MenuSearchItem.ID, by delta: Int, among visible: [MenuSearchItem.ID],
        for bundleID: String
    ) {
        guard var ids = pinsByApp[bundleID],
            let position = visible.firstIndex(of: id),
            visible.indices.contains(position + delta),
            let source = ids.firstIndex(of: id),
            let destination = ids.firstIndex(of: visible[position + delta])
        else { return }
        ids.swapAt(source, destination)
        pinsByApp[bundleID] = ids
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(pinsByApp)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            onPersistenceFailure?()
        }
    }

    private static func normalized(_ ids: [String]) -> [String] {
        var seen: Set<String> = []
        return Array(ids.filter { !$0.isEmpty && seen.insert($0).inserted }.prefix(capPerApp))
    }
}
