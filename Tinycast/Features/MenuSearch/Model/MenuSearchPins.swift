import Foundation

enum MenuSearchPins {
    /// A pin the snapshot cannot show is skipped, not forgotten: its submenu may just be unbuilt.
    static func split(
        _ items: [MenuSearchItem], pinned ids: [MenuSearchItem.ID]
    ) -> (pinned: [MenuSearchItem], rest: [MenuSearchItem]) {
        guard !ids.isEmpty else { return ([], items) }
        let byID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let pinned = ids.compactMap { byID[$0] }
        let pinnedIDs = Set(pinned.map(\.id))
        return (pinned, items.filter { !pinnedIDs.contains($0.id) })
    }
}
