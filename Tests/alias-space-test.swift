import Foundation

/// Space after an alias enters its arguments from the alias's start, and runs it only when whole.
@main
@MainActor
struct AliasSpaceTests {
    static var failures = 0
    static var passes = 0

    static func expect(
        _ actual: AliasSpacePolicy.Action?, _ expected: AliasSpacePolicy.Action?, _ message: String
    ) {
        if actual == expected {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message) — got \(String(describing: actual)), want \(String(describing: expected))")
        }
    }

    static func inputs(_ query: String, _ alias: String?) -> AliasSpacePolicy.Action? {
        AliasSpacePolicy.action(query: query, alias: alias, hasArguments: true)
    }

    static func noInputs(_ query: String, _ alias: String?) -> AliasSpacePolicy.Action? {
        AliasSpacePolicy.action(query: query, alias: alias, hasArguments: false)
    }

    static func main() {
        expect(inputs("translate", "translate"), .enterArguments, "the whole alias enters the inputs")
        expect(inputs("tr", "translate"), .enterArguments, "the start of the alias is enough, as in Raycast")
        expect(inputs("TR", "translate"), .enterArguments, "case folds the way the alias ranks")
        expect(inputs("gó", "go compose"), .enterArguments, "diacritics fold the way the alias ranks")
        expect(inputs("go", "go compose"), .enterArguments, "an alias with a space is reached from its first word")
        expect(inputs("go ", "go compose"), .enterArguments, "a typed space inside the alias still counts")
        expect(inputs("compose", "go compose"), nil, "a later word of the alias keeps the space")
        expect(inputs("late", "translate"), nil, "a match inside the alias keeps the space")
        expect(inputs("translates", "translate"), nil, "typing past the alias keeps the space")
        expect(inputs(" tr", "translate"), nil, "a leading space is not the alias's start")
        expect(inputs("", "translate"), nil, "an empty query never acts")
        expect(inputs("transl", nil), nil, "a title match without an alias keeps the space")

        expect(noInputs("sn", "sn"), .run, "the whole alias runs a command without inputs")
        expect(noInputs("SN", "sn"), .run, "running folds case the way the alias ranks")
        expect(noInputs("go compose", "go compose"), .run, "a whole alias with a space runs")
        expect(noInputs("s", "sn"), nil, "only the start of the alias never runs anything")
        expect(noInputs("go", "go compose"), nil, "the first word of a longer alias keeps the space")
        expect(noInputs("snx", "sn"), nil, "typing past the alias keeps the space")
        expect(noInputs("", "sn"), nil, "an empty query never runs")
        expect(noInputs("snippets", nil), nil, "a title match without an alias never runs")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }
}
