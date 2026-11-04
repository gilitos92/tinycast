import Foundation

/// The user's per-entry aliases, keyed like favorites and ranking by `preferenceKey`.
@MainActor
@Observable
final class AliasStore {
    private let defaults: UserDefaults
    private let defaultsKey = "launcherAliases"

    private(set) var aliases: [String: String]
    /// AppIndex includes this in its result key, invalidating a ranking when an alias changes.
    private(set) var revision = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        aliases = defaults.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
    }

    func alias(for entryKey: String) -> String? { aliases[entryKey] }

    /// Trimmed, since the field commits on ↵ or lost focus, never mid-word; blank means none.
    func setAlias(_ alias: String, for entryKey: String) {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = trimmed.isEmpty ? nil : trimmed
        guard aliases[entryKey] != value else { return }
        aliases[entryKey] = value
        revision &+= 1
        defaults.set(aliases, forKey: defaultsKey)
    }

    func removeKeys(_ keys: Set<String>) {
        let remaining = aliases.filter { !keys.contains($0.key) }
        guard remaining.count != aliases.count else { return }
        aliases = remaining
        revision &+= 1
        defaults.set(aliases, forKey: defaultsKey)
    }

    func replace(_ new: [String: String]) {
        // An import obeys the same rule as typing: blank means none, or it lands unclearable.
        aliases = new.compactMapValues {
            let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        revision &+= 1
        defaults.set(aliases, forKey: defaultsKey)
    }
}
