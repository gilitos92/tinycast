import Foundation

/// Space after an alias jumps into its arguments only from the alias's start.
@main
@MainActor
struct AliasSpaceTests {
    static var failures = 0
    static var passes = 0

    static func expect(_ actual: Bool, _ expected: Bool, _ message: String) {
        if actual == expected {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message) — got \(actual), want \(expected)")
        }
    }

    static func main() {
        expect(
            AliasSpacePolicy.entersArguments(query: "translate", alias: "translate"), true,
            "the whole alias jumps")
        expect(
            AliasSpacePolicy.entersArguments(query: "tr", alias: "translate"), true,
            "the start of the alias is enough, as in Raycast")
        expect(
            AliasSpacePolicy.entersArguments(query: "TR", alias: "translate"), true,
            "case folds the way the alias ranks")
        expect(
            AliasSpacePolicy.entersArguments(query: "gó", alias: "go compose"), true,
            "diacritics fold the way the alias ranks")
        expect(
            AliasSpacePolicy.entersArguments(query: "go", alias: "go compose"), true,
            "an alias with a space is still reached from its first word")
        expect(
            AliasSpacePolicy.entersArguments(query: "go ", alias: "go compose"), true,
            "a typed space inside the alias still counts as its start")

        expect(
            AliasSpacePolicy.entersArguments(query: "compose", alias: "go compose"), false,
            "a later word of the alias keeps the space, unlike the ranking's alternate-title hit")
        expect(
            AliasSpacePolicy.entersArguments(query: "late", alias: "translate"), false,
            "a match inside the alias keeps the space")
        expect(
            AliasSpacePolicy.entersArguments(query: "translates", alias: "translate"), false,
            "typing past the alias keeps the space")
        expect(
            AliasSpacePolicy.entersArguments(query: " tr", alias: "translate"), false,
            "a leading space is not the alias's start")
        expect(
            AliasSpacePolicy.entersArguments(query: "", alias: "translate"), false,
            "an empty query never jumps")
        expect(
            AliasSpacePolicy.entersArguments(query: "transl", alias: nil), false,
            "a title match without an alias keeps the space")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }
}
