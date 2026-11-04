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
        let aliasUnits = SearchText(alias, transliterated: false).units
        if hasArguments { return aliasUnits.starts(with: typed) ? .enterArguments : nil }
        return aliasUnits == typed ? .run : nil
    }
}
