//
//  Clean_TimesTests.swift
//  Clean TimesTests
//
//  Created by Pavel Arkharov on 1.6.2026.
//

import Testing
import Foundation
@testable import Clean_Times

@MainActor
struct Clean_TimesTests {

    @Test func samplePrincipleCollapsedLabelMatchesPlan() {
        let entry = PrincipleEntry.sample

        #expect("\(entry.displayDate) -- \(entry.keyword)" == "May 9 -- Love")
    }

    @Test func completedTimerRunIsConsumableOnce() {
        var currentDate = date("2026-06-08T08:00:00Z")
        let model = MeditationTimerModel(durationSeconds: 60) {
            currentDate
        }

        _ = model.begin()
        currentDate = date("2026-06-08T08:01:00Z")
        _ = model.tick()

        let run = model.consumeCompletedRun()

        #expect(run != nil)
        #expect(run?.plannedDurationSeconds == 60)
        #expect(run?.creditedDurationSeconds == 60)
        #expect(model.consumeCompletedRun() == nil)
    }

    @Test func resetBeforeCompletionRecordsNoCompletedRun() {
        let model = MeditationTimerModel(durationSeconds: 60) {
            date("2026-06-08T08:00:00Z")
        }

        _ = model.begin()
        model.reset()

        #expect(model.consumeCompletedRun() == nil)
    }

    @Test func sessionUsesStartDayAcrossMidnight() {
        let session = MeditationSession(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            startedAt: date("2026-06-07T20:58:00Z"),
            completedAt: date("2026-06-07T21:08:00Z"),
            plannedDurationSeconds: 600,
            timezoneIDAtStart: "Europe/Helsinki",
            completionSource: .timerReachedZero
        )

        #expect(session.localDayKey == "2026-06-07")
    }

    @Test func multipleSessionsOnOneDayAggregateIntoOnePracticeDay() {
        let sessions = [
            meditationSession(id: "00000000-0000-0000-0000-000000000011", startedAt: "2026-06-08T06:00:00Z", duration: 600),
            meditationSession(id: "00000000-0000-0000-0000-000000000012", startedAt: "2026-06-08T18:00:00Z", duration: 900)
        ]

        let days = MeditationPracticeSummary.aggregateDays(from: sessions)

        #expect(days.count == 1)
        #expect(days.first?.localDayKey == "2026-06-08")
        #expect(days.first?.completedSessionCount == 2)
        #expect(days.first?.totalCreditedSeconds == 1_500)
    }

    @Test func monthGridIncludesLeapDay() {
        let keys = CalendarMonth(year: 2028, month: 2)
            .gridCells
            .compactMap(\.localDayKey)

        #expect(keys.contains("2028-02-29"))
        #expect(!keys.contains("2028-02-30"))
    }

    @Test func sessionStoreRejectsDuplicateSessionIDs() {
        let suiteName = "CleanTimesMeditationSessionStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = MeditationSessionStore(userDefaults: defaults, storageKey: "sessions")
        let session = meditationSession(
            id: "00000000-0000-0000-0000-000000000021",
            startedAt: "2026-06-08T06:00:00Z",
            duration: 600
        )

        #expect(store.saveCompletedSession(session))
        #expect(!store.saveCompletedSession(session))
        #expect(store.sessions.count == 1)
    }

    private func meditationSession(id: String, startedAt: String, duration: TimeInterval) -> MeditationSession {
        let startedDate = date(startedAt)
        return MeditationSession(
            id: UUID(uuidString: id)!,
            startedAt: startedDate,
            completedAt: startedDate.addingTimeInterval(duration),
            plannedDurationSeconds: duration,
            timezoneIDAtStart: "UTC",
            completionSource: .timerReachedZero
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
