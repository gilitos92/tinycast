import Foundation

/// Quick AI's ⌘[ and ⌘]: the next older or newer saved chat, as Raycast steps through recent chats.
enum ChatNavigation {
    enum Direction: Sendable {
        case older
        case newer
    }

    enum Destination: Sendable, Equatable {
        case chat(UUID)
        case newChat
    }

    /// `ids` is the history, newest first; past the newest chat lies a new one, as in Raycast.
    static func destination(
        from current: UUID?, in ids: [UUID], direction: Direction, isAvailable: (UUID) -> Bool
    ) -> Destination? {
        let index = current.flatMap { ids.firstIndex(of: $0) }
        switch direction {
        case .older:
            let start = index.map { $0 + 1 } ?? 0
            return ids[start...].first(where: isAvailable).map(Destination.chat)
        case .newer:
            guard let index else { return nil }
            return ids[..<index].last(where: isAvailable).map(Destination.chat) ?? .newChat
        }
    }
}
