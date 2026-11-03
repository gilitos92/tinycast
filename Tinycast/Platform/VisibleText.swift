import Foundation

/// Text from outside, made safe to read before agreeing to it: nothing can hide, move or fake a line.
enum VisibleText {
    /// Spells out line breaks, invisibles, direction marks, blank letters, mark pile-ups and space runs.
    static func escaped(_ value: String) -> String {
        let scalars = Array(value.unicodeScalars)
        var result = ""
        var marksInRow = 0
        for (index, scalar) in scalars.enumerated() {
            marksInRow = isMark(scalar) ? marksInRow + 1 : 0
            switch scalar {
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case " ":
                let isEdge = index == 0 || index == scalars.count - 1
                result += isEdge || scalars[index - 1] == " " ? spelled(scalar) : " "
            default:
                result += hides(scalar) || marksInRow > maximumMarksInRow ? spelled(scalar) : String(scalar)
            }
        }
        return result
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
