import SwiftUI
import SwiftData

@main
struct IjarApp: App {
    @StateObject private var notificationService = NotificationService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PropertyMetadata.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(notificationService)
                .preferredColorScheme(.light) // Always use light mode
                .onAppear {
                    // Pass the notification service to app delegate when view appears
                    appDelegate.notificationService = notificationService
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
