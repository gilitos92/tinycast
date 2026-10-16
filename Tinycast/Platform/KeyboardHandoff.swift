import AppKit

extension NSRunningApplication {
    /// Hands the keyboard back after one of our panels held key without activating us.
    @MainActor
    func activateReclaimingKeyboard() {
        guard !isTerminated else { return }
        // Re-activating an already-active app is a no-op, which strands keys on our hidden panel.
        if isActive {
            NSApp.activate()
            NSApp.yieldActivation(to: self)
        }
        _ = activate(from: .current)
    }
}
