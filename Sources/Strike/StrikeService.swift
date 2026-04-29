import Foundation

final class StrikeService {
    var onActivityChanged: ((Bool) -> Void)?
    var onConnectionChanged: ((Bool) -> Void)?
    var onStatusMessage: ((String) -> Void)?

    private let settings = SettingsStore.shared
    private let player = GongPlayer()
    private let notifier = Notifier()
    private var realtime: SupabaseRealtimeClient?
    private var seenEventIDs = Set<String>()
    private let seenLock = NSLock()
    private var activityWorkItem: DispatchWorkItem?

    func connect() {
        guard settings.isConfigured else {
            SettingsWindowController.shared.show()
            return
        }

        realtime?.disconnect()
        let client = SupabaseRealtimeClient(settings: settings)
        client.onConnected = { [weak self] connected in
            self?.onConnectionChanged?(connected)
        }
        client.onStatusMessage = { [weak self] message in
            self?.onStatusMessage?(message)
        }
        client.onStrike = { [weak self] event in
            self?.receive(event)
        }
        realtime = client
        client.connect()
    }

    func disconnect() {
        realtime?.disconnect()
        realtime = nil
        onConnectionChanged?(false)
        onStatusMessage?("Disconnected")
    }

    func strike() {
        if realtime == nil {
            connect()
        }

        let event = StrikeEvent(
            id: UUID().uuidString,
            senderID: settings.clientID,
            senderName: settings.displayName.isEmpty ? NSUserName() : settings.displayName,
            scheduledAt: Date().timeIntervalSince1970 + 0.35
        )

        receive(event)
        realtime?.broadcast(event)
    }

    private func receive(_ event: StrikeEvent) {
        guard markSeen(event.id) else {
            return
        }

        player.play(at: event.scheduledAt)
        showActivity(until: event.scheduledAt + player.duration)

        if !event.isLocal {
            notifier.notifyStrike(from: event.senderName)
        }
    }

    private func markSeen(_ id: String) -> Bool {
        seenLock.lock()
        defer { seenLock.unlock() }

        if seenEventIDs.contains(id) {
            return false
        }

        seenEventIDs.insert(id)
        if seenEventIDs.count > 256 {
            seenEventIDs.remove(seenEventIDs.first!)
        }
        return true
    }

    private func showActivity(until epochTime: TimeInterval) {
        DispatchQueue.main.async {
            self.activityWorkItem?.cancel()
            self.onActivityChanged?(true)

            let delay = max(0.4, epochTime - Date().timeIntervalSince1970)
            let item = DispatchWorkItem { [weak self] in
                self?.onActivityChanged?(false)
            }
            self.activityWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
    }
}
