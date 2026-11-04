import Foundation

/// What Space after a typed alias does, as in Raycast; nil leaves it a typed space.
enum AliasSpacePolicy {
    enum Action: Equatable {
        case enterArguments
        case run
    }

    /// Inputs need only the alias's start; running needs all of it, so a stray `s␣` never launches.
    static func action(query: String, alias: String?, hasArguments: Bool) -> Action? {
        guard let alias else { return nil }
        let typed = SearchText(query, transliterated: false).units
        guard !typed.isEmpty else { return nil }
        // A store written before its field lost focus can keep a stray edge space the chip hides.
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let aliasUnits = SearchText(trimmed, transliterated: false).units
        if hasArguments { return aliasUnits.starts(with: typed) ? .enterArguments : nil }
        return aliasUnits == typed ? .run : nil
    }
}
