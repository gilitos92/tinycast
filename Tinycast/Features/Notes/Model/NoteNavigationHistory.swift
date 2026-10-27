import Foundation

/// The notes opened in this session, walked like a browser's history with ⌘[ and ⌘].
struct NoteNavigationHistory: Sendable, Equatable {
    enum Direction: Sendable {
        case back
        case forward
    }

    private(set) var back: [NoteID] = []
    private(set) var current: NoteID?
    private(set) var forward: [NoteID] = []

    static let limit = 50

    /// Opening a note any other way than ⌘[ or ⌘] starts a new branch, as a link does in a browser.
    mutating func visit(_ id: NoteID?) {
        guard id != current else { return }
        if let current {
            back.append(current)
            if back.count > Self.limit { back.removeFirst(back.count - Self.limit) }
        }
        forward = []
        current = id
        dropStepsInPlace()
    }

    /// The nearest note that still exists, so a note deleted behind Tinycast's back is stepped over.
    func target(_ direction: Direction, existing: Set<NoteID>) -> NoteID? {
        switch direction {
        case .back: back.last { existing.contains($0) }
        case .forward: forward.last { existing.contains($0) }
        }
    }

    /// Notes stepped over on the way to `target` are dropped rather than kept to fail again.
    mutating func move(_ direction: Direction, to target: NoteID) {
        switch direction {
        case .back:
            guard let index = back.lastIndex(of: target) else { return }
            if let current { forward.append(current) }
            back.removeSubrange(index...)
        case .forward:
            guard let index = forward.lastIndex(of: target) else { return }
            if let current { back.append(current) }
            forward.removeSubrange(index...)
        }
        current = target
    }

    mutating func rename(_ id: NoteID, to renamed: NoteID) {
        back = back.map { $0 == id ? renamed : $0 }
        forward = forward.map { $0 == id ? renamed : $0 }
        if current == id { current = renamed }
    }

    mutating func remove(_ id: NoteID) {
        back = Self.collapsed(back.filter { $0 != id })
        forward = Self.collapsed(forward.filter { $0 != id })
        if current == id { current = nil }
        dropStepsInPlace()
    }

    /// A step that would land on the note already open is a step that does nothing.
    private mutating func dropStepsInPlace() {
        while let last = back.last, last == current { back.removeLast() }
        while let last = forward.last, last == current { forward.removeLast() }
    }

    private static func collapsed(_ ids: [NoteID]) -> [NoteID] {
        ids.reduce(into: []) { result, id in
            if result.last != id { result.append(id) }
        }
    }
}
