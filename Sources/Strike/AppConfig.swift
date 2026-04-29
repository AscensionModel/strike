import Foundation

enum AppConfig {
    static let supabaseURL = "https://enmympaziigrdaogmdbf.supabase.co"
    static let supabaseAnonKey = "sb_publishable_XOblrggMAmE_LDt9la4ing_9XusUKQa"

    static var isRealtimeConfigured: Bool {
        supabaseURL.hasPrefix("https://")
            && !supabaseURL.contains("YOUR_PROJECT")
            && !supabaseAnonKey.contains("YOUR_SUPABASE")
            && !supabaseAnonKey.isEmpty
    }
}
