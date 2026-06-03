import AVFoundation
import Combine
import Foundation
import OSLog

@MainActor
final class MeditationAudioPlayer: ObservableObject {
    private enum Sound: Hashable {
        case singleGong
        case completionGong

        var resourceName: String {
            switch self {
            case .singleGong:
                "gong"
            case .completionGong:
                "gong_x3"
            }
        }
    }

    private let logger = Logger(subsystem: "dev.rkhrv.Clean-Times", category: "MeditationAudio")
    private var players: [Sound: AVAudioPlayer] = [:]
    private var hasConfiguredAudioSession = false

    func play(_ cue: MeditationTimerModel.Cue) {
        switch cue {
        case .start, .middle:
            play(.singleGong)
        case .end:
            play(.completionGong)
        }
    }

    func play(_ cues: [MeditationTimerModel.Cue]) {
        cues.forEach(play)
    }

    func stopAll() {
        players.values.forEach { player in
            player.stop()
            player.currentTime = 0
        }
    }

    private func play(_ sound: Sound) {
        configureAudioSessionIfNeeded()

        guard let player = player(for: sound) else { return }

        if player.isPlaying {
            player.stop()
        }

        player.currentTime = 0
        player.numberOfLoops = 0

        if !player.play() {
            logger.error("AVAudioPlayer refused to play \(sound.resourceName).caf")
        }
    }

    private func player(for sound: Sound) -> AVAudioPlayer? {
        if let player = players[sound] {
            return player
        }

        guard let url = resourceURL(for: sound) else {
            logger.debug("Missing meditation audio resource: \(sound.resourceName).caf")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 1
            player.prepareToPlay()
            players[sound] = player
            return player
        } catch {
            logger.error("Failed to load meditation audio resource \(sound.resourceName).caf: \(error.localizedDescription)")
            return nil
        }
    }

    private func configureAudioSessionIfNeeded() {
        guard !hasConfiguredAudioSession else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            hasConfiguredAudioSession = true
        } catch {
            logger.error("Failed to configure meditation audio session: \(error.localizedDescription)")
        }
    }

    private func resourceURL(for sound: Sound) -> URL? {
        Bundle.main.url(forResource: sound.resourceName, withExtension: "caf")
            ?? Bundle.main.url(
                forResource: sound.resourceName,
                withExtension: "caf",
                subdirectory: "Resources/Audio"
            )
            ?? Bundle.main.url(
                forResource: sound.resourceName,
                withExtension: "caf",
                subdirectory: "Audio"
            )
    }
}
