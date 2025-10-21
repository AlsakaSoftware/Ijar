import SwiftUI

extension View {
    /// Executes an async task once when the view is first created
    /// Unlike `.task`, this will not re-execute when the view reappears
    func onceTask(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        modifier(OnceTaskModifier(priority: priority, action: action))
    }
}

private struct OnceTaskModifier: ViewModifier {
    let priority: TaskPriority
    let action: @Sendable () async -> Void
    @State private var hasExecuted = false

    func body(content: Content) -> some View {
        content
            .task(priority: priority) {
                guard !hasExecuted else { return }
                hasExecuted = true
                await action()
            }
    }
}
