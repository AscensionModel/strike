import Foundation
import UserNotifications

final class Notifier {
    func notifyStrike(from name: String) {
        guard SettingsStore.shared.notificationsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Strike"
        content.body = "\(name) struck the gong"
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "strike-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
