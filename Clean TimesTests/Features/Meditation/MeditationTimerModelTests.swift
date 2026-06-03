import Foundation
import Testing
@testable import Clean_Times

@MainActor
struct MeditationTimerModelTests {
    @Test func idleStateDisplaysFullDuration() {
        let model = MeditationTimerModel(durationSeconds: 15 * 60)

        #expect(model.state == .idle)
        #expect(model.remainingSeconds == 15 * 60)
        #expect(model.formattedRemaining == "15:00")
    }

    @Test func beginChangesStateToRunningAndEmitsStartCue() {
        let model = MeditationTimerModel(durationSeconds: 10 * 60)

        let cues = model.begin()

        #expect(model.state == .running)
        #expect(cues == [.start])
    }

    @Test func pauseFreezesRemainingTime() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let model = MeditationTimerModel(durationSeconds: 10 * 60, now: { currentDate })

        _ = model.begin()
        currentDate = currentDate.addingTimeInterval(120)
        _ = model.pause()
        let pausedRemaining = model.remainingSeconds

        currentDate = currentDate.addingTimeInterval(120)
        _ = model.tick()

        #expect(model.state == .paused)
        #expect(model.remainingSeconds == pausedRemaining)
        #expect(model.formattedRemaining == "08:00")
    }

    @Test func resumeContinuesFromPausedRemainingTime() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let model = MeditationTimerModel(durationSeconds: 10 * 60, now: { currentDate })

        _ = model.begin()
        currentDate = currentDate.addingTimeInterval(120)
        _ = model.pause()

        currentDate = currentDate.addingTimeInterval(300)
        _ = model.resume()
        currentDate = currentDate.addingTimeInterval(30)
        _ = model.tick()

        #expect(model.state == .running)
        #expect(model.remainingSeconds == 450)
        #expect(model.formattedRemaining == "07:30")
    }

    @Test func endCueFiresTenSecondsBeforeCompletionAndCompletionReachesZero() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let model = MeditationTimerModel(durationSeconds: 60, now: { currentDate })

        _ = model.begin()
        currentDate = currentDate.addingTimeInterval(28)
        #expect(model.tick() == [.middle])

        currentDate = currentDate.addingTimeInterval(22)
        #expect(model.tick() == [.end])
        #expect(model.state == .running)
        #expect(model.formattedRemaining == "00:10")

        currentDate = currentDate.addingTimeInterval(10)
        #expect(model.tick() == [])
        #expect(model.state == .completed)
        #expect(model.remainingSeconds == 0)
        #expect(model.formattedRemaining == "00:00")

        currentDate = currentDate.addingTimeInterval(30)
        #expect(model.tick() == [])
    }

    @Test func middleCueFiresTwoSecondsBeforeMidpointAndOnlyOnce() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let model = MeditationTimerModel(durationSeconds: 20 * 60, now: { currentDate })

        _ = model.begin()
        currentDate = currentDate.addingTimeInterval((10 * 60) - 3)
        #expect(model.tick() == [])

        currentDate = currentDate.addingTimeInterval(1)

        #expect(model.tick() == [.middle])
        #expect(model.tick() == [])

        currentDate = currentDate.addingTimeInterval(1)
        #expect(model.tick() == [])
    }

    @Test func resetReturnsToIdle() {
        var currentDate = Date(timeIntervalSinceReferenceDate: 0)
        let model = MeditationTimerModel(durationSeconds: 5 * 60, now: { currentDate })

        _ = model.begin()
        currentDate = currentDate.addingTimeInterval(90)
        _ = model.tick()
        model.reset()

        #expect(model.state == .idle)
        #expect(model.remainingSeconds == 5 * 60)
        #expect(model.formattedRemaining == "05:00")
    }

    @Test func durationChangesAreAcceptedOnlyWhenIdle() {
        let model = MeditationTimerModel(durationSeconds: 5 * 60)

        model.setDuration(seconds: 10 * 60)
        #expect(model.durationSeconds == 10 * 60)

        _ = model.begin()
        model.setDuration(seconds: 20 * 60)
        #expect(model.durationSeconds == 10 * 60)

        _ = model.pause()
        model.setDuration(seconds: 15 * 60)
        #expect(model.durationSeconds == 10 * 60)
    }

    @Test func durationIsClampedToSaneRange() {
        let model = MeditationTimerModel(durationSeconds: 10)

        #expect(model.durationSeconds == MeditationTimerModel.minimumDurationSeconds)

        model.setDuration(seconds: 10_000)
        #expect(model.durationSeconds == MeditationTimerModel.maximumDurationSeconds)
    }
}
