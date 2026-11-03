import Foundation

/// What a reader checks before snippets from a link are added: every field, quoted and spelled out.
enum SnippetLinkReview {
    /// Spelled out so a line break, the one that would run a command on expansion, is always visible.
    static func details(of snippets: [Snippet]) -> String {
        snippets.map { snippet in
            var lines = ["name: " + quoted(snippet.name)]
            if let keyword = snippet.keyword, !keyword.isEmpty {
                lines.append("keyword: " + quoted(keyword))
            }
            lines.append("text: " + quoted(snippet.text))
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    private static func quoted(_ value: String) -> String {
        let literal = value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"" + VisibleText.escaped(literal) + "\""
    }
}
