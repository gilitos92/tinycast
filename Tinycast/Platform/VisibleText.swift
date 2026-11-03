import Foundation

/// One named value a reader checks before agreeing; both halves are spelled out, `\` included.
struct ReviewLine: Sendable, Equatable {
    let name: String
    let value: String

    init(name: String, value: String) {
        self.name = VisibleText.escaped(name.replacingOccurrences(of: "\\", with: "\\\\"))
        self.value = VisibleText.escaped(value.replacingOccurrences(of: "\\", with: "\\\\"))
    }

    /// JSON escapes its own backslashes and line breaks, so doubling them again would mislead.
    init(name: String, json: String) {
        self.name = VisibleText.escaped(name.replacingOccurrences(of: "\\", with: "\\\\"))
        self.value = VisibleText.escaped(json)
    }
}

/// Text from outside, made safe to read before agreeing to it: nothing can hide, move or fake a line.
enum VisibleText {
    /// Spells out line breaks, invisibles, direction marks, blank letters, mark pile-ups and space runs.
    static func escaped(_ value: String) -> String {
        let scalars = Array(value.unicodeScalars)
        var result = ""
        var marksInRow = 0
        for (index, scalar) in scalars.enumerated() {
            marksInRow = isMark(scalar) ? marksInRow + 1 : 0
            let previous = index > 0 ? scalars[index - 1] : nil
            let next = index + 1 < scalars.count ? scalars[index + 1] : nil
            switch scalar {
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case " ", "\u{3000}":
                let isEdge = previous == nil || next == nil
                result += isEdge || isSpace(previous) ? spelled(scalar) : String(scalar)
            case "\u{200D}" where isEmoji(previous) && isEmoji(next):
                result += String(scalar)
            case "\u{FE0F}" where isEmoji(previous):
                result += String(scalar)
            default:
                result += hides(scalar) || marksInRow > maximumMarksInRow ? spelled(scalar) : String(scalar)
            }
        }
        return result
    }

    /// Either kind of space after another makes a run, which could push text onto a fake line.
    private static func isSpace(_ scalar: Unicode.Scalar?) -> Bool {
        scalar == " " || scalar == "\u{3000}"
    }

    /// A joiner or presentation selector only shapes emoji; elsewhere it could hide in plain text.
    private static func isEmoji(_ scalar: Unicode.Scalar?) -> Bool {
        guard let scalar else { return false }
        let properties = scalar.properties
        return scalar == "\u{FE0F}" || properties.isEmojiPresentation
            || (properties.isEmoji && scalar.value > 0xFF) || properties.isEmojiModifier
    }

    /// More than this many stacked marks can paint over the lines around them.
    private static let maximumMarksInRow = 2
    /// Letters that render as nothing but are not classed as ignorable.
    private static let blankLetters: Set<UInt32> = [0x2800, 0x3164, 0x115F, 0x1160, 0xFFA0]

    private static func hides(_ scalar: Unicode.Scalar) -> Bool {
        let properties = scalar.properties
        if properties.isDefaultIgnorableCodePoint || properties.isBidiControl { return true }
        if blankLetters.contains(scalar.value) { return true }
        switch properties.generalCategory {
        case .control, .format, .lineSeparator, .paragraphSeparator, .spaceSeparator, .privateUse,
            .surrogate, .unassigned:
            return true
        default:
            return false
        }
    }

    private static func isMark(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .nonspacingMark, .enclosingMark, .spacingMark: true
        default: false
        }
    }

    private static func spelled(_ scalar: Unicode.Scalar) -> String {
        "\\u{" + String(scalar.value, radix: 16, uppercase: true) + "}"
    }
}
