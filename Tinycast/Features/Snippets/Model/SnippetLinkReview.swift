import Foundation

/// What a reader checks before snippets from a link are added: every field, quoted and escaped.
enum SnippetLinkReview {
    /// Quoted so a line break, the one that would run a command on expansion, is always visible.
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
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let json = (try? encoder.encode(value)).flatMap { String(bytes: $0, encoding: .utf8) } ?? value
        // JSON leaves Unicode's own line separators raw, and a Text would still break on them.
        return json.unicodeScalars.map { scalar in
            CharacterSet.newlines.contains(scalar)
                ? "\\u{" + String(scalar.value, radix: 16, uppercase: true) + "}" : String(scalar)
        }.joined()
    }
}
