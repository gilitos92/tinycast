import Foundation

/// What a reader checks before snippets from a link are added: every field of every snippet.
enum SnippetLinkReview {
    /// Spelled out, so a line break that would run a command on expansion is always visible.
    static func details(of snippets: [Snippet]) -> [[ReviewLine]] {
        snippets.map { snippet in
            var lines = [ReviewLine(name: "name", value: snippet.name)]
            if let keyword = snippet.keyword, !keyword.isEmpty {
                lines.append(ReviewLine(name: "keyword", value: keyword))
            }
            lines.append(ReviewLine(name: "text", value: snippet.text))
            return lines
        }
    }
}
