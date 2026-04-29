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
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectAttempt = 0
    private var shouldStayConnected = false

    func connect() {
        guard settings.isConfigured else {
            SettingsWindowController.shared.show()
            return
        }

        shouldStayConnected = true
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        startRealtimeClient()
    }

    func disconnect() {
        shouldStayConnected = false
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        reconnectAttempt = 0
        realtime?.disconnect()
        realtime = nil
        onConnectionChanged?(false)
        onStatusMessage?("Disconnected")
    }

    private func startRealtimeClient() {
        realtime?.disconnect(notify: false)
        let client = SupabaseRealtimeClient(settings: settings)
        client.onConnected = { [weak self, weak client] connected in
            DispatchQueue.main.async {
                guard let self, self.realtime === client else {
                    return
                }

                if connected {
                    self.reconnectAttempt = 0
                    self.reconnectWorkItem?.cancel()
                    self.reconnectWorkItem = nil
                } else {
                    self.realtime = nil
                    self.scheduleReconnect()
                }

                self.onConnectionChanged?(connected)
            }
        }
        client.onStatusMessage = { [weak self, weak client] message in
            DispatchQueue.main.async {
                guard let self, self.realtime === client else {
                    return
                }

                self.onStatusMessage?(message)
            }
        }
        client.onStrike = { [weak self] event in
            self?.receive(event)
        }
        realtime = client
        client.connect()
    }

    private func scheduleReconnect() {
        guard shouldStayConnected, settings.isConfigured, reconnectWorkItem == nil else {
            return
        }

        reconnectAttempt += 1
        let delay = min(30, 2 << min(reconnectAttempt - 1, 4))
        onStatusMessage?("Connection lost. Reconnecting in \(delay)s")

        let item = DispatchWorkItem { [weak self] in
            guard let self, self.shouldStayConnected else {
                return
            }

            self.reconnectWorkItem = nil
            self.onStatusMessage?("Reconnecting...")
            self.startRealtimeClient()
        }
        reconnectWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: item)
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
