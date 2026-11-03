import Foundation

/// Whether Space after a typed alias jumps into its command's arguments, as Raycast's does.
enum AliasSpacePolicy {
    /// The start of the alias is enough; a match anywhere else, or on the title, keeps the space.
    static func entersArguments(query: String, alias: String?) -> Bool {
        guard let alias else { return false }
        let typed = SearchText(query, transliterated: false).units
        guard !typed.isEmpty else { return false }
        return SearchText(alias, transliterated: false).units.starts(with: typed)
    }
}
