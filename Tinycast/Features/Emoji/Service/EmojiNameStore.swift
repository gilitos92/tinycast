import Foundation

/// Names the user gave emoji, keyed by base glyph; the catalog name stays searchable beside them.
@MainActor
@Observable
final class EmojiNameStore {
    /// The catalog is currently smaller; this only bounds a malformed or hand-edited file.
    private static let cap = 3_000
    static let maxLength = 100

    private let fileURL: URL
    private(set) var names: [String: String]
    private(set) var revision = 0
    @ObservationIgnored var onPersistenceFailure: (() -> Void)?

    init(fileURL: URL = AppPaths.applicationSupport().appendingPathComponent("emoji-names.json")) {
        self.fileURL = fileURL
        let decoded =
            (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
        names = Self.normalized(decoded)
    }

    func name(for glyph: String) -> String? { names[glyph] }

    /// A blank name resets the glyph to its catalog name.
    func setName(_ name: String, for glyph: String) {
        guard !glyph.isEmpty else { return }
        let cleaned = Self.cleaned(name)
        guard names[glyph] != cleaned else { return }
        names[glyph] = cleaned
        didChange()
    }

    /// Restores names from a backup, dropping blanks.
    func replace(_ imported: [String: String]) {
        names = Self.normalized(imported)
        didChange()
    }

    private func didChange() {
        revision &+= 1
        do {
            let data = try JSONEncoder().encode(names)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            onPersistenceFailure?()
        }
    }

    private static func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(maxLength))
    }

    private static func normalized(_ names: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (glyph, name) in names.sorted(by: { $0.key < $1.key }) where !glyph.isEmpty {
            guard let cleaned = cleaned(name) else { continue }
            result[glyph] = cleaned
            if result.count == cap { break }
        }
        return result
    }
}
