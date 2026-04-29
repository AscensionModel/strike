import Foundation

final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let teamChannel = "teamChannel"
        static let displayName = "displayName"
        static let notificationsEnabled = "notificationsEnabled"
        static let autoConnect = "autoConnect"
        static let volume = "volume"
        static let clientID = "clientID"
        static let hasCompletedFirstLaunch = "hasCompletedFirstLaunch"
    }

    private init() {
        if defaults.string(forKey: Key.clientID) == nil {
            defaults.set(UUID().uuidString, forKey: Key.clientID)
        }
        if defaults.string(forKey: Key.teamChannel) == nil {
            defaults.set(Self.generateTeamCode(), forKey: Key.teamChannel)
        }
        if defaults.string(forKey: Key.teamChannel) == "default" {
            defaults.set(Self.generateTeamCode(), forKey: Key.teamChannel)
        }
        if defaults.string(forKey: Key.displayName) == nil {
            defaults.set(NSUserName(), forKey: Key.displayName)
        }
        if defaults.object(forKey: Key.notificationsEnabled) == nil {
            defaults.set(true, forKey: Key.notificationsEnabled)
        }
        if defaults.object(forKey: Key.autoConnect) == nil {
            defaults.set(true, forKey: Key.autoConnect)
        }
        if defaults.object(forKey: Key.volume) == nil {
            defaults.set(0.8, forKey: Key.volume)
        }
    }

    var teamChannel: String {
        get { defaults.string(forKey: Key.teamChannel) ?? Self.generateTeamCode() }
        set { defaults.set(Self.slug(newValue), forKey: Key.teamChannel) }
    }

    var displayName: String {
        get { defaults.string(forKey: Key.displayName) ?? NSUserName() }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.displayName) }
    }

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Key.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled) }
    }

    var autoConnect: Bool {
        get { defaults.bool(forKey: Key.autoConnect) }
        set { defaults.set(newValue, forKey: Key.autoConnect) }
    }

    var volume: Float {
        get {
            let value = defaults.object(forKey: Key.volume) as? Double ?? 0.8
            return min(1, max(0, Float(value)))
        }
        set {
            defaults.set(Double(min(1, max(0, newValue))), forKey: Key.volume)
        }
    }

    var clientID: String {
        defaults.string(forKey: Key.clientID) ?? "unknown-client"
    }

    var hasCompletedFirstLaunch: Bool {
        defaults.bool(forKey: Key.hasCompletedFirstLaunch)
    }

    var isConfigured: Bool {
        AppConfig.isRealtimeConfigured && !teamChannel.isEmpty
    }

    func markFirstLaunchComplete() {
        defaults.set(true, forKey: Key.hasCompletedFirstLaunch)
    }

    func regenerateTeamCode() {
        teamChannel = Self.generateTeamCode()
    }

    private static func slug(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = trimmed.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let slug = String(scalars).lowercased()
        return slug.isEmpty ? generateTeamCode() : slug
    }

    private static func generateTeamCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let characters = (0..<8).map { _ in alphabet.randomElement()! }
        let raw = String(characters)
        let split = raw.index(raw.startIndex, offsetBy: 4)
        return "\(raw[..<split])-\(raw[split...])".lowercased()
    }
}
