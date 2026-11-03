import SwiftUI

/// A dialog's read-only detail box: it scrolls rather than cuts, so nothing approved stays unseen.
struct DialogDetailsField: View {
    @Environment(\.metrics) private var metrics
    let text: String

    var body: some View {
        ScrollView {
            Text(verbatim: text)
                .font(metrics.typography.code)
                .foregroundStyle(Theme.Colors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(metrics.spacing.md)
        }
        .frame(height: metrics.size.dialogTextHeight)
        .background(
            Theme.Colors.controlSurface,
            in: RoundedRectangle(cornerRadius: metrics.radius.row, style: .continuous))
    }
}
