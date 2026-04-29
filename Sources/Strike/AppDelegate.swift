import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusItemController?
    private let strikeService = StrikeService()
    private let settings = SettingsStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        statusController = StatusItemController(strikeService: strikeService)
        strikeService.onActivityChanged = { [weak self] active in
            DispatchQueue.main.async {
                self?.statusController?.setActive(active)
            }
        }
        strikeService.onConnectionChanged = { [weak self] connected in
            DispatchQueue.main.async {
                self?.statusController?.setConnected(connected)
            }
        }
        strikeService.onStatusMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.statusController?.setStatusMessage(message)
            }
        }

        if settings.autoConnect {
            strikeService.connect()
        }

        if !settings.isConfigured || !settings.hasCompletedFirstLaunch {
            SettingsWindowController.shared.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        strikeService.disconnect()
    }
}
