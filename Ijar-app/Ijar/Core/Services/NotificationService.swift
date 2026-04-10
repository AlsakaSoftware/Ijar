import Foundation
import UIKit
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined

    private let deviceTokenRepository = DeviceTokenRepository()

    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }

    /// Check status and request permission if not determined
    func checkAndRequestNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus

        if settings.authorizationStatus == .notDetermined {
            await requestNotificationPermission()
        }
    }

    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            self.notificationPermissionStatus = granted ? .authorized : .denied

            if granted {
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
        await deviceTokenRepository.saveDeviceToken(tokenData, for: userId)
    }

    func removeDeviceToken(for userId: String) async {
        await deviceTokenRepository.removeDeviceToken(for: userId)
    }

    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "new_properties":
                print("Navigating to new properties")
            default:
                print("Unknown notification type: \(notificationType)")
            }
        }
    }
}
