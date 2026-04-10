import Foundation

final class DeviceTokenRepository {
    private let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }

    func saveDeviceToken(_ tokenData: Data, for userId: String) async {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()

#if DEBUG
        print("DeviceTokenRepository: Saving device token for user \(userId)")
#endif

        do {
            struct TokenBody: Encodable {
                let token: String
                let deviceType: String
            }

            try await networkService.send(
                endpoint: "/api/device-tokens",
                method: .put,
                body: TokenBody(token: tokenString, deviceType: "ios")
            )

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
            try await networkService.send(
                endpoint: "/api/device-tokens",
                method: .delete
            )

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
