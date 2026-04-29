import AppKit
import AVFoundation
import Foundation

final class GongPlayer {
    private let settings = SettingsStore.shared
    private let queue = DispatchQueue(label: "strike.gong-player")
    private var players: [AVAudioPlayer] = []
    private lazy var soundDuration: TimeInterval = loadDuration()

    var duration: TimeInterval {
        soundDuration
    }

    func play(at epochTime: TimeInterval) {
        let delay = max(0, epochTime - Date().timeIntervalSince1970)
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.playNow()
        }
    }

    private func playNow() {
        guard let url = AppResources.url(forResource: "gong", withExtension: "wav") else {
            NSSound.beep()
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = settings.volume
            player.prepareToPlay()
            player.play()
            players.append(player)
            players.removeAll { !$0.isPlaying }
        } catch {
            NSSound.beep()
        }
    }

    private func loadDuration() -> TimeInterval {
        guard let url = AppResources.url(forResource: "gong", withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return 3.2
        }

        return player.duration
    }
}
