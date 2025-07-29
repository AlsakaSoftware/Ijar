import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: Configuration.supabaseURL)!
        let supabaseKey = Configuration.supabaseAnonKey
        
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
}

// MARK: - Configuration
extension SupabaseManager {
    struct Configuration {
        static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://snkitffkozxfgkaoisxd.supabase.co"
        static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNua2l0ZmZrb3p4ZmdrYW9pc3hkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NDg5NzgsImV4cCI6MjA2OTMyNDk3OH0._08hMX09Xp8noGPllIZiX6QSPaQiPjH2akv6TgUZzkc"
        
        static var isConfigured: Bool {
            return !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
        }
    }
}
