import Foundation

final class SupabaseRealtimeClient {
    var onConnected: ((Bool) -> Void)?
    var onStrike: ((StrikeEvent) -> Void)?
    var onStatusMessage: ((String) -> Void)?

    private let settings: SettingsStore
    private var task: URLSessionWebSocketTask?
    private var heartbeatTimer: Timer?
    private var ref = 0
    private var joinRef: String?
    private var isJoined = false
    private var pendingBroadcasts: [[String: Any]] = []
    private let callbackQueue = DispatchQueue(label: "strike.supabase-realtime")

    init(settings: SettingsStore) {
        self.settings = settings
    }

    func connect() {
        guard let url = websocketURL() else {
            onConnected?(false)
            return
        }

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: url)
        self.task = task
        isJoined = false
        pendingBroadcasts.removeAll()
        onStatusMessage?("Connecting to Supabase Realtime")
        task.resume()
        receiveLoop()
        joinChannel()
        startHeartbeat()
    }

    func disconnect() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isJoined = false
        pendingBroadcasts.removeAll()
        onConnected?(false)
        onStatusMessage?("Disconnected")
    }

    func broadcast(_ strike: StrikeEvent) {
        guard let payload = try? JSONEncoder().encode(strike),
              let json = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            return
        }

        let broadcastPayload: [String: Any] = [
            "type": "broadcast",
            "event": "strike",
            "payload": json
        ]

        if isJoined {
            send(topic: channelTopic, event: "broadcast", payload: broadcastPayload, includeJoinRef: true)
        } else {
            pendingBroadcasts.append(broadcastPayload)
            onStatusMessage?("Queued strike until channel joins")
        }
    }

    private var channelTopic: String {
        "realtime:team:\(settings.teamChannel)"
    }

    private func websocketURL() -> URL? {
        guard var components = URLComponents(string: AppConfig.supabaseURL) else {
            return nil
        }

        components.scheme = components.scheme == "http" ? "ws" : "wss"
        components.path = "/realtime/v1/websocket"
        components.queryItems = [
            URLQueryItem(name: "apikey", value: AppConfig.supabaseAnonKey),
            URLQueryItem(name: "vsn", value: "1.0.0")
        ]
        return components.url
    }

    private func joinChannel() {
        let ref = nextRef()
        joinRef = ref
        send(
            topic: channelTopic,
            event: "phx_join",
            payload: [
                "config": [
                    "broadcast": ["ack": false, "self": false],
                    "presence": ["enabled": true, "key": settings.clientID],
                    "postgres_changes": [],
                    "private": false
                ]
            ],
            ref: ref,
            joinRef: ref
        )
    }

    private func startHeartbeat() {
        DispatchQueue.main.async {
            self.heartbeatTimer?.invalidate()
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
                self?.send(topic: "phoenix", event: "heartbeat", payload: [:], includeJoinRef: false)
            }
        }
    }

    private func send(topic: String, event: String, payload: [String: Any], includeJoinRef: Bool) {
        send(
            topic: topic,
            event: event,
            payload: payload,
            ref: nextRef(),
            joinRef: includeJoinRef ? joinRef : nil
        )
    }

    private func send(topic: String, event: String, payload: [String: Any], ref: String, joinRef: String?) {
        var message: [String: Any] = [
            "topic": topic,
            "event": event,
            "payload": payload,
            "ref": ref
        ]

        if let joinRef {
            message["join_ref"] = joinRef
        }

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            return
        }

        task?.send(.string(text)) { error in
            if error != nil {
                self.onConnected?(false)
                self.onStatusMessage?("Realtime send failed")
            }
        }
    }

    private func nextRef() -> String {
        ref += 1
        return "\(ref)"
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success(let message):
                self.handle(message)
                self.receiveLoop()
            case .failure:
                self.isJoined = false
                self.onConnected?(false)
                self.onStatusMessage?("Realtime receive failed")
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        let data: Data?
        switch message {
        case .string(let text):
            data = text.data(using: .utf8)
        case .data(let raw):
            data = raw
        @unknown default:
            data = nil
        }

        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = object["event"] as? String else {
            return
        }

        if event == "phx_reply",
           let payload = object["payload"] as? [String: Any],
           let status = payload["status"] as? String {
            let isJoinReply = (object["ref"] as? String) == joinRef

            if isJoinReply && status == "ok" {
                isJoined = true
                onConnected?(true)
                onStatusMessage?("Joined \(settings.teamChannel)")
                flushPendingBroadcasts()
            } else if isJoinReply {
                isJoined = false
                onConnected?(false)
                onStatusMessage?("Realtime join failed")
            }
            return
        }

        guard event == "broadcast",
              let payload = object["payload"] as? [String: Any],
              let broadcastEvent = payload["event"] as? String,
              broadcastEvent == "strike",
              let strikePayload = payload["payload"] else {
            return
        }

        parseStrike(strikePayload)
    }

    private func flushPendingBroadcasts() {
        let broadcasts = pendingBroadcasts
        pendingBroadcasts.removeAll()

        for payload in broadcasts {
            send(topic: channelTopic, event: "broadcast", payload: payload, includeJoinRef: true)
        }
    }

    private func parseStrike(_ payload: Any) {
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload),
              let strike = try? JSONDecoder().decode(StrikeEvent.self, from: data) else {
            return
        }

        callbackQueue.async {
            self.onStrike?(strike)
        }
    }
}
