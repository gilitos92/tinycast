import Foundation

/// The parsed catalog: sections precomputed at load, search memoized one query deep.
@MainActor
@Observable
final class EmojiIndex {
    private(set) var entries: [EmojiEntry] = []
    private(set) var categorySections: [(category: EmojiCategory, entries: [EmojiEntry])] = []

    /// `order` is the catalog index, the tie-break that keeps equal scores in catalog order.
    private struct ScoredEntry {
        let entry: EmojiEntry
        let score: Int
        let order: Int
        let isLiteral: Bool
    }

    /// An entry's text folded once at load, so a keystroke folds only the query.
    private struct FoldedEntry: Sendable {
        let name: FuzzyMatch.Candidate
        let keywords: FuzzyMatch.Candidate
        let keywordList: [FuzzyMatch.Candidate]

        init(_ entry: EmojiEntry) {
            self.init(name: entry.name, keywords: entry.keywords)
        }

        init(name: String, keywords: String) {
            self.name = FuzzyMatch.Candidate(name)
            self.keywords = FuzzyMatch.Candidate(keywords)
            keywordList = keywords.split(separator: ",").map { FuzzyMatch.Candidate(String($0)) }
        }
    }

    private struct SearchKey: Equatable {
        let query: String
        let revision: Int
        let frequentID: ObjectIdentifier
        let frequentRevision: Int
        let customNames: [String: String]
        let limit: Int
    }

    private var byGlyph: [String: EmojiEntry] = [:]
    /// Parallel to `entries`.
    private var foldedEntries: [FoldedEntry] = []
    @ObservationIgnored private var searchMemo = Memo<SearchKey, [EmojiEntry]>()
    /// Bumped on each load, so the key above names the catalog it scored.
    private var revision = 0

    var isLoaded: Bool { !entries.isEmpty }

    /// `languages` pick which of the bundle's keyword packs join the catalog's English keywords.
    func load(_ raw: String = EmojiData.raw, languages: [String] = [], bundle: Bundle = .main) async {
        let (parsed, folded) = await Task.detached(priority: .utility) {
            let parsed = EmojiCatalog.parse(raw, localized: Self.keywordPacks(for: languages, in: bundle))
            return (parsed, parsed.map(FoldedEntry.init))
        }.value
        entries = parsed
        foldedEntries = folded
        var grouped: [EmojiCategory: [EmojiEntry]] = [:]
        for entry in parsed { grouped[entry.category, default: []].append(entry) }
        categorySections = EmojiCategory.allCases.compactMap { category in
            grouped[category].map { (category, $0) }
        }
        byGlyph = Dictionary(parsed.map { ($0.glyph, $0) }, uniquingKeysWith: { first, _ in first })
        revision &+= 1
    }

    /// Plain files let search follow macOS languages independently of the app's UI language.
    private nonisolated static func keywordPacks(for languages: [String], in bundle: Bundle) -> [String] {
        let urls = bundle.urls(forResourcesWithExtension: "txt", subdirectory: "EmojiKeywords") ?? []
        let byLanguage = Dictionary(
            urls.map { ($0.deletingPathExtension().lastPathComponent, $0) },
            uniquingKeysWith: { first, _ in first })
        return EmojiCatalog.keywordLanguages(available: byLanguage.keys.sorted(), preferred: languages)
            .compactMap { byLanguage[$0].flatMap { try? String(contentsOf: $0, encoding: .utf8) } }
    }

    func entry(for glyph: String) -> EmojiEntry? { byGlyph[glyph] }

    /// Ranked fuzzy matches; a custom name scores as a name beside the catalog's. Empty finds none.
    func search(
        _ query: String, frequent: FrequentEmojiStore, customNames: [String: String] = [:],
        limit: Int = 320
    ) -> [EmojiEntry] {
        let trimmed = FuzzyMatch.normalized(query).trimmingCharacters(in: .whitespacesAndNewlines)
        let unwrapped =
            trimmed.count > 2 && trimmed.first == ":" && trimmed.last == ":"
            ? String(trimmed.dropFirst().dropLast()) : trimmed
        let words = unwrapped.split(whereSeparator: \.isWhitespace).map(String.init)
        let q = words.joined(separator: " ")
        guard !q.isEmpty, limit > 0 else { return [] }
        let key = SearchKey(
            query: q, revision: revision, frequentID: ObjectIdentifier(frequent),
            frequentRevision: frequent.revision, customNames: customNames, limit: limit)
        return searchMemo.value(for: key) {
            let query = FuzzyMatch.Query(q)
            let terms = words.count > 1 ? words : []
            let frequentGlyphs = frequent.top(Self.frecencyLimit)
            let frecency = Dictionary(
                frequentGlyphs.enumerated().map {
                    ($0.element, Self.frecencyLimit - $0.offset)
                }, uniquingKeysWith: max)
            let recency = Dictionary(
                frequent.recent().enumerated().map { ($0.element, $0.offset) },
                uniquingKeysWith: min)
            var scored: [ScoredEntry] = []
            for (order, entry) in entries.enumerated() {
                let catalogScore = Self.textScore(query, terms: terms, folded: foldedEntries[order])
                let customScore = customNames[entry.glyph].flatMap {
                    Self.textScore(
                        query, terms: terms, folded: FoldedEntry(name: $0, keywords: entry.keywords))
                }
                guard let textScore = [catalogScore, customScore].compactMap(\.self).max()
                else { continue }
                let score =
                    if textScore >= Self.literalScoreFloor, let rank = recency[entry.glyph] {
                        Self.recentScore - rank
                    } else {
                        textScore + (frecency[entry.glyph] ?? 0)
                    }
                scored.append(
                    ScoredEntry(
                        entry: entry, score: score, order: order,
                        isLiteral: textScore >= Self.literalScoreFloor))
            }
            // Scattered letters are a fallback: "kiss" must not surface Saint Kitts & Nevis.
            if scored.contains(where: \.isLiteral) { scored.removeAll { !$0.isLiteral } }
            return
                scored
                .sorted { $0.score != $1.score ? $0.score > $1.score : $0.order < $1.order }
                .prefix(limit)
                .map(\.entry)
        }
    }

    /// Just under half a tier, so an equal-quality name match always wins.
    private static let keywordPenalty = 500
    private static let frecencyLimit = 100
    /// A complete leading name word: above an exact keyword, below the exact name.
    private static let leadingWordScore = 95_000
    /// A complete later name word: below a leading one, still above an exact keyword.
    private static let laterWordScore = 94_900
    /// The floor of every literal hit; a scattered subsequence scores in the hundreds at most.
    private static let literalScoreFloor = 40_000
    /// Above every text tier: a used emoji that matches as a word leads, last used first.
    private static let recentScore = 1_000_000
    /// Scattered query words rank below every literal phrase, name-only words first.
    private static let nameWordsScore = 60_000
    private static let mixedWordsScore = 50_000

    private static func textScore(
        _ query: FuzzyMatch.Query, terms: [String], folded: FoldedEntry
    ) -> Int? {
        var nameOnly = true
        for term in terms where !containsWordStart(term, in: folded.name.text) {
            guard !term.contains(","), containsWordStart(term, in: folded.keywords.text) else { return nil }
            nameOnly = false
        }

        let nameMatch = FuzzyMatch.match(query, candidate: folded.name)
        if nameMatch?.tier == .exact { return nameMatch?.score }
        var best = nameMatch?.score
        if let nameMatch, nameMatch.tier == .prefix,
            let next = folded.name.text.dropFirst(nameMatch.queryLength).first,
            !next.isLetter && !next.isNumber
        {
            best = leadingWordScore - nameMatch.candidateLength
        } else if let nameMatch, nameMatch.tier == .wordStart,
            endsWord(at: nameMatch.offset + nameMatch.queryLength, in: folded.name.text)
        {
            best = laterWordScore - nameMatch.candidateLength
        }
        if !terms.isEmpty {
            let ordered = nameMatch?.tier == .subsequence ? nameMatch?.score ?? 0 : 0
            best = max(best ?? Int.min, (nameOnly ? nameWordsScore : mixedWordsScore) + ordered)
        }
        guard !folded.keywordList.isEmpty, FuzzyMatch.score(query, candidate: folded.keywords) != nil
        else { return best }
        for keyword in folded.keywordList {
            guard let match = FuzzyMatch.match(query, candidate: keyword) else { continue }
            best = max(best ?? Int.min, min(match.score, leadingWordScore) - keywordPenalty)
            if match.tier == .exact { break }
        }
        return best
    }

    private static func endsWord(at offset: Int, in text: String) -> Bool {
        guard let next = text.dropFirst(offset).first else { return true }
        return !next.isLetter && !next.isNumber
    }

    private static func containsWordStart(_ term: String, in candidate: String) -> Bool {
        var start = candidate.startIndex
        while let range = candidate.range(of: term, range: start..<candidate.endIndex) {
            if range.lowerBound == candidate.startIndex { return true }
            let previous = candidate[candidate.index(before: range.lowerBound)]
            if !previous.isLetter && !previous.isNumber { return true }
            start = candidate.index(after: range.lowerBound)
        }
        return false
    }
}
