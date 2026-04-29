import AppKit

final class StatusItemController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let strikeService: StrikeService
    private var active = false
    private var connected = false
    private var statusMessage = "Not connected"

    init(strikeService: StrikeService) {
        self.strikeService = strikeService
        super.init()

        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusClick(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        renderIcon()
    }

    func setActive(_ active: Bool) {
        self.active = active
        renderIcon()
    }

    func setConnected(_ connected: Bool) {
        self.connected = connected
        renderIcon()
    }

    func setStatusMessage(_ statusMessage: String) {
        self.statusMessage = statusMessage
        renderIcon()
    }

    @objc private func handleStatusClick(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showMenu()
        } else {
            strikeService.strike()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let strikeItem = NSMenuItem(title: "Strike Gong", action: #selector(strikeFromMenu), keyEquivalent: "")
        strikeItem.target = self
        menu.addItem(strikeItem)

        let connectionTitle = connected ? "Disconnect" : "Connect"
        let connectionItem = NSMenuItem(title: connectionTitle, action: #selector(toggleConnection), keyEquivalent: "")
        connectionItem.target = self
        menu.addItem(connectionItem)

        let copyTeamCodeItem = NSMenuItem(title: "Copy Team Code", action: #selector(copyTeamCode), keyEquivalent: "")
        copyTeamCodeItem.target = self
        menu.addItem(copyTeamCodeItem)

        menu.addItem(.separator())

        let statusMenuItem = NSMenuItem(title: statusMessage, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Strike", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func renderIcon() {
        statusItem.button?.image = StatusIcon.image(active: active, connected: connected)
        statusItem.button?.toolTip = connected ? "Strike - \(SettingsStore.shared.teamChannel)" : "Strike - \(statusMessage)"
    }

    @objc private func strikeFromMenu() {
        strikeService.strike()
    }

    @objc private func toggleConnection() {
        if connected {
            strikeService.disconnect()
        } else {
            strikeService.connect()
        }
    }

    @objc private func copyTeamCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(SettingsStore.shared.teamChannel, forType: .string)
        setStatusMessage("Copied team code \(SettingsStore.shared.teamChannel)")
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
