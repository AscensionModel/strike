import Foundation

struct StrikeEvent: Codable, Hashable {
    let id: String
    let senderID: String
    let senderName: String
    let scheduledAt: TimeInterval

    var isLocal: Bool {
        senderID == SettingsStore.shared.clientID
    }
}
