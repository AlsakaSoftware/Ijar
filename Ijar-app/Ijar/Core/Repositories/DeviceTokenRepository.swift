import Foundation
import Supabase

final class DeviceTokenRepository {
    private let supabase: SupabaseClient

    init() {
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: ConfigManager.shared.supabaseURL)!,
            supabaseKey: ConfigManager.shared.supabaseAnonKey
        )
    }

    func saveDeviceToken(_ tokenData: Data, for userId: String) async {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

#if DEBUG
        print("DeviceTokenRepository: Saving device token for user \(userId)")
#endif

        do {
            try await supabase
                .from("device_tokens")
                .upsert([
                    "user_id": userId,
                    "device_token": tokenString,
                    "device_type": "ios"
                ])
                .execute()

#if DEBUG
            print("DeviceTokenRepository: Successfully saved device token")
#endif
        } catch {
#if DEBUG
            print("DeviceTokenRepository: Failed to save device token: \(error)")
#endif
        }
    }

    func removeDeviceToken(for userId: String) async {
        do {
            try await supabase
                .from("device_tokens")
                .delete()
                .eq("user_id", value: userId)
                .execute()

#if DEBUG
            print("DeviceTokenRepository: Removed device tokens for user \(userId)")
#endif
        } catch {
#if DEBUG
            print("DeviceTokenRepository: Failed to remove device token: \(error)")
#endif
        }
    }
}
