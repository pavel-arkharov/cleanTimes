import Combine
import Foundation

@MainActor
final class MeditationTimerModel: ObservableObject {
    enum State: Equatable {
        case idle
        case running
        case paused
        case completed
    }

    enum Cue: Equatable {
        case start
        case middle
        case end
    }

    static let minimumDurationSeconds: TimeInterval = 60
    static let maximumDurationSeconds: TimeInterval = 7_200
    static let middleCueLeadTimeSeconds: TimeInterval = 2
    static let endCueLeadTimeSeconds: TimeInterval = 10

    @Published private(set) var state: State = .idle
    @Published private(set) var durationSeconds: TimeInterval
    @Published private(set) var remainingSeconds: TimeInterval

    private let now: () -> Date
    private var startedAt: Date?
    private var pausedAt: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var hasPlayedMiddleGong = false
    private var hasPlayedEndGong = false

    init(durationSeconds: TimeInterval, now: @escaping () -> Date = { Date() }) {
        let clampedDuration = Self.clampedDuration(durationSeconds)
        self.durationSeconds = clampedDuration
        self.remainingSeconds = clampedDuration
        self.now = now
    }

    var canEditDuration: Bool {
        state == .idle
    }

    var showsResetControl: Bool {
        state != .idle
    }

    var primaryButtonTitle: String {
        switch state {
        case .idle, .completed:
            "Begin"
        case .running:
            "Pause"
        case .paused:
            "Resume"
        }
    }

    var primaryAccessibilityLabel: String {
        switch state {
        case .idle, .completed:
            "Begin meditation"
        case .running:
            "Pause meditation"
        case .paused:
            "Resume meditation"
        }
    }

    var formattedRemaining: String {
        let wholeSeconds = max(Int(ceil(remainingSeconds)), 0)
        return String(format: "%02d:%02d", wholeSeconds / 60, wholeSeconds % 60)
    }

    var timerAccessibilityLabel: String {
        "Meditation timer, \(accessibilityDurationText) remaining"
    }

    func performPrimaryAction() -> [Cue] {
        switch state {
        case .idle, .completed:
            begin()
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func begin() -> [Cue] {
        let currentDate = now()
        state = .running
        startedAt = currentDate
        pausedAt = nil
        accumulatedPausedDuration = 0
        remainingSeconds = durationSeconds
        hasPlayedMiddleGong = false
        hasPlayedEndGong = false
        return [.start]
    }

    func pause() -> [Cue] {
        guard state == .running else { return [] }

        let currentDate = now()
        let cues = refresh(at: currentDate)

        guard state == .running else { return cues }
        state = .paused
        pausedAt = currentDate
        return cues
    }

    func resume() -> [Cue] {
        guard state == .paused else { return [] }

        let currentDate = now()
        if let pausedAt {
            accumulatedPausedDuration += max(currentDate.timeIntervalSince(pausedAt), 0)
        }
        pausedAt = nil
        state = .running
        return []
    }

    func reset() {
        state = .idle
        remainingSeconds = durationSeconds
        startedAt = nil
        pausedAt = nil
        accumulatedPausedDuration = 0
        hasPlayedMiddleGong = false
        hasPlayedEndGong = false
    }

    func setDuration(seconds: TimeInterval) {
        guard state == .idle else { return }

        let clampedDuration = Self.clampedDuration(seconds)
        durationSeconds = clampedDuration
        remainingSeconds = clampedDuration
    }

    func tick() -> [Cue] {
        guard state == .running else { return [] }
        return refresh(at: now())
    }

    static func clampedDuration(_ seconds: TimeInterval) -> TimeInterval {
        min(max(seconds, minimumDurationSeconds), maximumDurationSeconds)
    }

    private func refresh(at currentDate: Date) -> [Cue] {
        guard state == .running, let startedAt else { return [] }

        let elapsed = max(currentDate.timeIntervalSince(startedAt) - accumulatedPausedDuration, 0)
        let updatedRemaining = max(durationSeconds - elapsed, 0)
        remainingSeconds = updatedRemaining

        if updatedRemaining <= 0 {
            state = .completed
            remainingSeconds = 0

            guard !hasPlayedEndGong else { return [] }
            hasPlayedEndGong = true
            return [.end]
        }

        if !hasPlayedEndGong, updatedRemaining <= Self.endCueLeadTimeSeconds {
            hasPlayedEndGong = true
            return [.end]
        }

        if !hasPlayedMiddleGong, elapsed >= middleCueElapsedThreshold {
            hasPlayedMiddleGong = true
            return [.middle]
        }

        return []
    }

    private var accessibilityDurationText: String {
        let wholeSeconds = max(Int(ceil(remainingSeconds)), 0)
        let minutes = wholeSeconds / 60
        let seconds = wholeSeconds % 60

        if seconds == 0 {
            return "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }

        let minuteText = "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
        let secondText = "\(seconds) \(seconds == 1 ? "second" : "seconds")"
        return "\(minuteText), \(secondText)"
    }

    private var middleCueElapsedThreshold: TimeInterval {
        max((durationSeconds / 2) - Self.middleCueLeadTimeSeconds, 0)
    }
}
