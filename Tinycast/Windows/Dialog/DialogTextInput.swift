import SwiftUI

/// A class, so the caller can read the typed text back after the dialog.
@MainActor
@Observable
final class DialogTextInputState {
    let placeholder: String
    let maxLength: Int
    var text: String

    init(text: String, placeholder: String, maxLength: Int) {
        self.text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }
}

struct DialogTextInputField: View {
    @Bindable var state: DialogTextInputState

    var body: some View {
        TextField("", text: $state.text, prompt: Text(state.placeholder))
            .dialogTextField()
            .onChange(of: state.text) { _, text in
                if text.count > state.maxLength { state.text = String(text.prefix(state.maxLength)) }
            }
            .accessibilityLabel(state.placeholder)
    }
}
