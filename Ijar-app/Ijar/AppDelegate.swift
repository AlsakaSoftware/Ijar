import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    var notificationService: NotificationService?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🎯 AppDelegate: Device token registered: \(tokenString)")
        
        // Save to UserDefaults for later use when user logs in
        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        print("💾 AppDelegate: Saved device token to UserDefaults")
        
        // If notification service is available and user is logged in, save immediately
        if let notificationService = notificationService {
            print("📤 AppDelegate: NotificationService is available, checking for logged in user...")
            // Get user ID from Supabase if available
            Task {
                if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
                    print("👤 AppDelegate: Found user ID: \(userId), saving token to Supabase...")
                    await notificationService.saveDeviceToken(deviceToken, for: userId)
                } else {
                    print("⏳ AppDelegate: No user logged in yet, token will be saved after login")
                }
            }
        } else {
            print("⏳ AppDelegate: NotificationService not yet available")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received remote notification: \(userInfo)")
        notificationService?.handleNotificationTap(userInfo: userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        notificationService?.handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
}