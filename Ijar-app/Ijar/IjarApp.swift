import SwiftUI

@main
struct IjarApp: App {
    @StateObject private var notificationService = NotificationService()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
    }
}
