import SwiftUI

/// What a details box shows, and whether the reader has seen all of it.
@MainActor
@Observable
final class DialogDetailsState {
    let text: String
    private(set) var hasReadAll = false

    init(text: String) {
        self.text = text
    }

    func markReadAll() {
        hasReadAll = true
    }
}

/// A dialog's read-only detail box: it scrolls rather than cuts, and agreeing waits for its end.
struct DialogDetailsField: View {
    @Environment(\.metrics) private var metrics
    let state: DialogDetailsState

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spacing.sm) {
            ScrollView {
                Text(verbatim: state.text)
                    .font(metrics.typography.code)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(metrics.spacing.md)
            }
            .scrollIndicators(.visible)
            // The app hides scrollers until a scroll, so the end is checked rather than trusted to show.
            .onScrollGeometryChange(for: Bool.self, of: Self.reachesEnd) { _, atEnd in
                if atEnd { state.markReadAll() }
            }
            .frame(height: metrics.size.dialogTextHeight)
            .background(
                Theme.Colors.controlSurface,
                in: RoundedRectangle(cornerRadius: metrics.radius.row, style: .continuous))
            // Hidden, not removed: the panel is sized once, and a vanished line would leave a gap.
            Text("Scroll to the end to continue.")
                .font(metrics.typography.rowTrailing)
                .foregroundStyle(Theme.Colors.textSecondary)
                .opacity(state.hasReadAll ? 0 : 1)
        }
    }

    private static func reachesEnd(_ geometry: ScrollGeometry) -> Bool {
        geometry.visibleRect.maxY >= geometry.contentSize.height - 1
    }
}
