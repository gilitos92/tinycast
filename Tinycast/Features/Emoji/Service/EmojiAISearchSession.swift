import Foundation
import FoundationModels

/// Asks the on-device model for emoji by meaning, for a query whose words name none or on ⇥.
@MainActor
@Observable
final class EmojiAISearchSession {
    enum Phase: Equatable {
        case searching
        case finished([String])
        case failed(String)
    }

    /// The guide's ceiling below: past it the on-device model mostly repeats itself.
    static let limit = 16

    /// The query `phase` answers, so a reply to an older one is never shown under a newer one.
    private(set) var query: String?
    private(set) var phase: Phase?
    @ObservationIgnored private var task: Task<Void, Never>?
    private let index: EmojiIndex
    private let aiSettings: AISettingsStore
    private let settings: AppSettings

    init(index: EmojiIndex, aiSettings: AISettingsStore, settings: AppSettings) {
        self.index = index
        self.aiSettings = aiSettings
        self.settings = settings
    }

    /// AI switched off, or its on-device route switched off in Settings → AI, is off here too.
    var isAvailable: Bool {
        settings.aiEnabled && aiSettings.isRouteEnabled(.appleIntelligence)
            && AppleIntelligenceProvider.status().isAvailable
    }

    /// Nil while unavailable, so an answer kept from before AI was switched off never shows.
    func phase(for query: String) -> Phase? {
        isAvailable && self.query == Self.normalized(query) ? phase : nil
    }

    /// Asking again for the query on screen reuses its answer unless that answer was a failure.
    func search(_ query: String) {
        let query = Self.normalized(query)
        guard !query.isEmpty, isAvailable else { return }
        if self.query == query, let phase, !phase.isFailure { return }
        task?.cancel()
        self.query = query
        phase = .searching
        task = Task { [weak self] in
            let result: Phase
            do {
                let replies = try await Self.suggestions(for: query)
                guard let self else { return }
                result = .finished(
                    EmojiCatalog.catalogGlyphs(in: replies, limit: Self.limit) {
                        self.index.entry(for: $0) != nil
                    })
            } catch is CancellationError {
                return
            } catch let error as LanguageModelSession.GenerationError {
                result = .failed(
                    AppleIntelligenceProvider.providerError(error).errorDescription
                        ?? Self.failureMessage)
            } catch {
                result = .failed(Self.failureMessage)
            }
            guard let self, !Task.isCancelled, self.query == query else { return }
            phase = result
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        query = nil
        phase = nil
    }

    private static var failureMessage: String {
        String(localized: "Apple Intelligence could not search for emoji.")
    }

    private static func normalized(_ query: String) -> String {
        query.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    @concurrent
    private static func suggestions(for query: String) async throws -> [String] {
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(
            to: "Search: \(query)", generating: EmojiSuggestions.self,
            options: GenerationOptions(temperature: 0.3))
        return response.content.emoji
    }

    private nonisolated static let instructions = """
        You find emoji for a search typed into an emoji picker. The search may be a word, a phrase, \
        a feeling or a situation, in any language. Answer with the emoji whose meaning fits it best, \
        best match first: the obvious one, then related objects, faces, places and symbols. Each \
        item is exactly one emoji and nothing else.
        """
}

@Generable
private struct EmojiSuggestions {
    @Guide(
        description: "Several different emoji that fit the search, best match first",
        .count(6...16))
    var emoji: [String]
}

extension EmojiAISearchSession.Phase {
    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
