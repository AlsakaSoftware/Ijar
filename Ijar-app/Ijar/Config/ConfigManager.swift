import Foundation

struct ConfigManager {
    static let shared = ConfigManager()
    
    private let config: [String: Any]
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist file not found or invalid format")
        }
        self.config = plist
    }
    
    var supabaseURL: String {
        guard let url = config["SupabaseURL"] as? String,
              !url.isEmpty,
              url != "YOUR_SUPABASE_PROJECT_URL" else {
            fatalError("SupabaseURL not configured in Config.plist")
        }
        return url
    }
    
    var supabaseAnonKey: String {
        guard let key = config["SupabaseAnonKey"] as? String,
              !key.isEmpty,
              key != "YOUR_SUPABASE_ANON_KEY" else {
            fatalError("SupabaseAnonKey not configured in Config.plist")
        }
        return key
    }
    
    var environment: String {
        return config["Environment"] as? String ?? "Development"
    }
    
    var isDevelopment: Bool {
        return environment == "Development"
    }
    
    var isProduction: Bool {
        return environment == "Production"
    }
    
    var githubToken: String? {
        return config["GitHubToken"] as? String
    }

    var revenueCatApiKey: String {
        guard let key = config["RevenueCatApiKey"] as? String,
              !key.isEmpty else {
            fatalError("RevenueCatApiKey not configured in Config.plist")
        }
        return key
    }
}

// MARK: - Debug Helper
#if DEBUG
extension ConfigManager {
    func debugPrint() {
        print("🔧 Config Manager Debug:")
        print("   Environment: \(environment)")
        print("   Supabase URL: \(supabaseURL.prefix(30))...")
        print("   Supabase Key: \(supabaseAnonKey.prefix(20))...")
    }
}
#endif
