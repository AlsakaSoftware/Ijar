import Foundation
import UIKit
import UserNotifications
import Supabase

@MainActor
class NotificationService: ObservableObject {
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let supabase: SupabaseClient
    
    init() {
        // Initialize Supabase client using ConfigManager
        let config = ConfigManager.shared
        
        guard let url = URL(string: config.supabaseURL) else {
            fatalError("Invalid Supabase URL in configuration")
        }

        supabase = SupabaseClient(supabaseURL: url, supabaseKey: config.supabaseAnonKey)
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.notificationPermissionStatus = granted ? .authorized : .denied
            
            if granted {
                // Register for remote notifications
                registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            self.notificationPermissionStatus = .denied
            return false
        }
    }
    
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func saveDeviceToken(_ tokenData: Data, for userId: String) async {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("🚀 NotificationService: Attempting to save device token to Supabase...")
        print("   User ID: \(userId)")
        print("   Token: \(tokenString)")
        
        do {
            let response = try await supabase
                .from("device_tokens")
                .upsert([
                    "user_id": userId,
                    "device_token": tokenString,
                    "device_type": "ios"
                ])
                .execute()
            
            print("✅ NotificationService: Successfully saved device token to Supabase!")
            print("   Response: \(response)")
        } catch {
            print("❌ NotificationService: Failed to save device token!")
            print("   Error: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
    
    func removeDeviceToken(for userId: String) async {
        do {
            let _ = try await supabase
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            print("Successfully removed device tokens for user: \(userId)")
        } catch {
            print("Error removing device token: \(error)")
        }
    }
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Handle notification tap - can navigate to specific content
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "new_properties":
                // Navigate to properties list or specific query
                print("Navigating to new properties")
            default:
                print("Unknown notification type: \(notificationType)")
            }
        }
    }
}
