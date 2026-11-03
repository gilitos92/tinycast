import Foundation

struct ExtensionDeepLink: Sendable, Equatable {
    enum Route: Sendable, Equatable {
        case command(ExtensionDeepLink)
        case storeInstall(StoreInstall)
    }

    struct StoreInstall: Sendable, Equatable, Identifiable {
        let handle: String
        let name: String

        var id: String { "\(handle)/\(name)" }
    }

    let ownerOrAuthor: String?
    let extensionName: String
    let commandName: String
    let arguments: [String: String]
    let fallbackText: String?
    let launchType: ExtensionLaunchType
    let launchContext: [String: RenderValue]

    /// `owner/ext` first so a scoped manifest wins over a bare slug collision.
    var extensionCandidates: [String] {
        guard let ownerOrAuthor, !ownerOrAuthor.isEmpty else { return [extensionName] }
        return ["\(ownerOrAuthor)/\(extensionName)", extensionName]
    }

    func matches(manifestName: String) -> Bool {
        let lowered = manifestName.lowercased()
        if extensionCandidates.contains(where: { $0.lowercased() == lowered }) { return true }
        return manifestName.split(separator: "/").last?.lowercased() == extensionName.lowercased()
    }

    static func claims(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return ["raycast", "tinycast", "tinycast-dev", "com.raycast", "raycastinternal"].contains(scheme)
    }

    /// Reads back through `route(url:)`, owner-scoped names included; `scheme` is the channel's.
    static func url(
        extensionName: String, commandName: String, arguments: [String: String], scheme: String
    ) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "extensions"
        components.path = "/\(extensionName)/\(commandName)"
        if !arguments.isEmpty, let encoded = encodedArguments(arguments) {
            components.percentEncodedQueryItems = [URLQueryItem(name: "arguments", value: encoded)]
        }
        return components.url
    }

    /// Encoded strictly, so `parseArguments` reads back exactly what was typed.
    private static func encodedArguments(_ arguments: [String: String]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let unreserved = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return (try? encoder.encode(arguments))
            .flatMap { String(bytes: $0, encoding: .utf8) }
            .flatMap { $0.addingPercentEncoding(withAllowedCharacters: unreserved) }
    }

    static func parse(url: URL) -> ExtensionDeepLink? {
        guard case .command(let link)? = route(url: url) else { return nil }
        return link
    }

    /// Host and first path segment unify `raycast://extensions/…` and `com.raycast:/extensions/…`.
    static func route(url: URL) -> Route? {
        guard claims(url) else { return nil }
        var segments: [String] = []
        if let host = url.host, !host.isEmpty { segments.append(host) }
        segments += url.pathComponents.filter { $0 != "/" }
        segments = segments.map { $0.removingPercentEncoding ?? $0 }
        guard segments.count >= 3, segments[0].lowercased() == "extensions" else { return nil }
        let body = Array(segments.dropFirst())
        guard body.count >= 2 else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if body.count == 2,
            items.contains(where: { $0.name.lowercased() == "source" && $0.value == "webstore" })
        {
            return .storeInstall(StoreInstall(handle: body[0], name: body[1]))
        }
        let ownerOrAuthor: String?
        let extensionName: String
        let commandName: String
        switch body.count {
        case 2:
            ownerOrAuthor = nil
            extensionName = body[0]
            commandName = body[1]
        case 3:
            ownerOrAuthor = body[0]
            extensionName = body[1]
            commandName = body[2]
        default:
            ownerOrAuthor = body.dropLast(2).joined(separator: "/")
            extensionName = body[body.count - 2]
            commandName = body[body.count - 1]
        }
        guard !extensionName.isEmpty, !commandName.isEmpty else { return nil }
        var arguments: [String: String] = [:]
        var fallbackText: String?
        var launchType = ExtensionLaunchType.userInitiated
        var launchContext: [String: RenderValue] = [:]
        for item in items {
            switch field(named: item.name) {
            case .arguments:
                if let raw = item.value { arguments = parseArguments(raw) }
            case .fallbackText:
                fallbackText = item.value
            case .launchType:
                launchType = Self.launchType(item.value)
            case .launchContext:
                if let raw = item.value { launchContext = parseContext(raw) }
            case nil:
                break
            }
        }
        return .command(
            ExtensionDeepLink(
                ownerOrAuthor: ownerOrAuthor, extensionName: extensionName, commandName: commandName,
                arguments: arguments, fallbackText: fallbackText, launchType: launchType,
                launchContext: launchContext))
    }

    enum Field {
        case arguments, fallbackText, launchType, launchContext

        /// The name a reader sees, whichever spelling the link used.
        var name: String {
            switch self {
            case .arguments: "arguments"
            case .fallbackText: "fallbackText"
            case .launchType: "launchType"
            case .launchContext: "context"
            }
        }
    }

    /// The one field each accepted spelling sets; nil for a parameter no command reads.
    static func field(named name: String) -> Field? {
        switch name.lowercased() {
        case "arguments": .arguments
        case "fallbacktext": .fallbackText
        case "launchtype", "launch_type": .launchType
        case "context", "launchcontext": .launchContext
        default: nil
        }
    }

    /// The same link with only the arguments its command declares, the only ones a reader sees.
    func keepingArguments(named declared: Set<String>) -> ExtensionDeepLink {
        ExtensionDeepLink(
            ownerOrAuthor: ownerOrAuthor, extensionName: extensionName, commandName: commandName,
            arguments: arguments.filter { declared.contains($0.key) }, fallbackText: fallbackText,
            launchType: launchType, launchContext: launchContext)
    }

    /// The fields a command reads, as parsed and cut to `declaredArguments`: what shows is what runs.
    static func reviewLines(
        ofPercentEncodedQuery query: String?, declaredArguments: Set<String>? = nil
    ) -> [ReviewLine] {
        var components = URLComponents()
        components.percentEncodedQuery = query
        return (components.queryItems ?? []).flatMap { item -> [ReviewLine] in
            guard let field = field(named: item.name), let raw = item.value, !raw.isEmpty else { return [] }
            switch field {
            case .arguments:
                return parseArguments(raw).filter { declaredArguments?.contains($0.key) ?? true }
                    .sorted { $0.key < $1.key }
                    .map { ReviewLine(name: "arguments." + $0.key, value: $0.value) }
            case .fallbackText:
                return [ReviewLine(name: field.name, value: raw)]
            case .launchType:
                let background = launchType(raw) == .background
                return [ReviewLine(name: field.name, value: background ? "background" : "userInitiated")]
            case .launchContext:
                return [ReviewLine(name: field.name, json: reencodedContext(raw))]
            }
        }
    }

    static func launchType(_ raw: String?) -> ExtensionLaunchType {
        raw?.lowercased() == "background" ? .background : .userInitiated
    }

    /// What the command receives, after `parseContext` and its conversions, not what was sent.
    private static func reencodedContext(_ raw: String) -> String {
        let received = parseContext(raw).mapValues(\.jsonValue)
        guard JSONSerialization.isValidJSONObject(received),
            let encoded = try? JSONSerialization.data(
                withJSONObject: received, options: [.sortedKeys, .withoutEscapingSlashes])
        else { return "{}" }
        return String(bytes: encoded, encoding: .utf8) ?? "{}"
    }

    /// Whether two parameters set the same field, in any of its spellings.
    static func repeatsField(inPercentEncodedQuery query: String?) -> Bool {
        var components = URLComponents()
        components.percentEncodedQuery = query
        let fields = (components.queryItems ?? []).compactMap { field(named: $0.name) }
        return Set(fields).count != fields.count
    }

    nonisolated static func parseContext(_ raw: String) -> [String: RenderValue] {
        guard let data = raw.data(using: .utf8),
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return [:] }
        return object.mapValues(RenderValue.init(json:))
    }

    /// Raycast sends one URL-encoded JSON object; anything else means no arguments, not a failure.
    nonisolated static func parseArguments(_ raw: String) -> [String: String] {
        guard let data = raw.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
            let dict = json as? [String: Any]
        else { return [:] }
        var out: [String: String] = [:]
        for (key, value) in dict {
            if let string = value as? String {
                out[key] = string
            } else if let number = value as? NSNumber {
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    out[key] = number.boolValue ? "true" : "false"
                } else {
                    let double = number.doubleValue
                    out[key] =
                        double == double.rounded() && double.magnitude < 1e15
                        ? String(number.int64Value) : String(double)
                }
            } else if value is NSNull {
                out[key] = ""
            }
        }
        return out
    }
}
