import Combine
import Foundation

enum MeditationCompletionSource: String, Codable, Equatable {
    case timerReachedZero
    case restoredAfterBackground
    case manualRepair
}

struct MeditationSession: Identifiable, Codable, Equatable {
    static let schemaVersion = 1

    let id: UUID
    let startedAt: Date
    let completedAt: Date
    let plannedDurationSeconds: TimeInterval
    let creditedDurationSeconds: TimeInterval
    let localDayKey: String
    let timezoneIDAtStart: String
    let completionSource: MeditationCompletionSource
    let schemaVersion: Int

    init(
        id: UUID = UUID(),
        startedAt: Date,
        completedAt: Date,
        plannedDurationSeconds: TimeInterval,
        creditedDurationSeconds: TimeInterval? = nil,
        timezoneIDAtStart: String,
        completionSource: MeditationCompletionSource,
        calendar: Calendar = .gregorianUTC
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.creditedDurationSeconds = creditedDurationSeconds ?? plannedDurationSeconds
        self.localDayKey = Self.localDayKey(
            for: startedAt,
            timezoneID: timezoneIDAtStart,
            calendar: calendar
        )
        self.timezoneIDAtStart = timezoneIDAtStart
        self.completionSource = completionSource
        self.schemaVersion = Self.schemaVersion
    }

    static func localDayKey(
        for date: Date,
        timezoneID: String,
        calendar baseCalendar: Calendar = .gregorianUTC
    ) -> String {
        var calendar = baseCalendar
        calendar.timeZone = TimeZone(identifier: timezoneID) ?? .current

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}

struct PracticeDay: Identifiable, Equatable {
    var id: String { localDayKey }

    let localDayKey: String
    let completedSessionCount: Int
    let totalCreditedSeconds: TimeInterval
    let firstStartedAt: Date
    let lastCompletedAt: Date
}

struct MeditationPracticeSummary {
    static func aggregateDays(from sessions: [MeditationSession]) -> [PracticeDay] {
        let grouped = Dictionary(grouping: sessions, by: \.localDayKey)

        return grouped.map { dayKey, sessions in
            let sortedByStart = sessions.sorted { $0.startedAt < $1.startedAt }
            let sortedByCompletion = sessions.sorted { $0.completedAt < $1.completedAt }

            return PracticeDay(
                localDayKey: dayKey,
                completedSessionCount: sessions.count,
                totalCreditedSeconds: sessions.reduce(0) { $0 + $1.creditedDurationSeconds },
                firstStartedAt: sortedByStart.first?.startedAt ?? .distantPast,
                lastCompletedAt: sortedByCompletion.last?.completedAt ?? .distantPast
            )
        }
        .sorted { $0.localDayKey < $1.localDayKey }
    }

    static func dayMap(from sessions: [MeditationSession]) -> [String: PracticeDay] {
        Dictionary(uniqueKeysWithValues: aggregateDays(from: sessions).map { ($0.localDayKey, $0) })
    }

    static func totalCreditedSeconds(in sessions: [MeditationSession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.creditedDurationSeconds }
    }
}

@MainActor
final class MeditationSessionStore: ObservableObject {
    @Published private(set) var sessions: [MeditationSession]

    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "meditationCompletedSessions.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.sessions = Self.loadSessions(from: userDefaults, key: storageKey)
    }

    @discardableResult
    func saveCompletedSession(_ session: MeditationSession) -> Bool {
        guard session.plannedDurationSeconds > 0 else {
            return false
        }

        guard !sessions.contains(where: { $0.id == session.id }) else {
            return false
        }

        sessions.append(session)
        sessions.sort { $0.startedAt < $1.startedAt }
        persist()
        return true
    }

    func completedSessions(in range: ClosedRange<String>) -> [MeditationSession] {
        sessions.filter { range.contains($0.localDayKey) }
    }

    func completedSessions(on localDayKey: String) -> [MeditationSession] {
        sessions.filter { $0.localDayKey == localDayKey }
    }

    func completedSessions(year: Int, month: Int) -> [MeditationSession] {
        let range = CalendarMonth.localDayKeyRange(year: year, month: month)
        return completedSessions(in: range)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sessions) else {
            return
        }

        userDefaults.set(data, forKey: storageKey)
    }

    private static func loadSessions(from userDefaults: UserDefaults, key: String) -> [MeditationSession] {
        guard
            let data = userDefaults.data(forKey: key),
            let sessions = try? JSONDecoder().decode([MeditationSession].self, from: data)
        else {
            return []
        }

        return sessions.sorted { $0.startedAt < $1.startedAt }
    }
}

struct CalendarMonth: Equatable {
    let year: Int
    let month: Int

    init(containing date: Date = .now, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
    }

    init(year: Int, month: Int) {
        var adjustedYear = year
        var adjustedMonth = month

        while adjustedMonth < 1 {
            adjustedYear -= 1
            adjustedMonth += 12
        }

        while adjustedMonth > 12 {
            adjustedYear += 1
            adjustedMonth -= 12
        }

        self.year = adjustedYear
        self.month = adjustedMonth
    }

    func advanced(by offset: Int) -> CalendarMonth {
        CalendarMonth(year: year, month: month + offset)
    }

    var title: String {
        guard let date = Calendar.gregorianUTC.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return ""
        }

        return date.formatted(.dateTime.month(.wide).year())
    }

    var localDayKeyRange: ClosedRange<String> {
        Self.localDayKeyRange(year: year, month: month)
    }

    var gridCells: [CalendarDayCell] {
        Self.gridCells(year: year, month: month)
    }

    static func localDayKeyRange(year: Int, month: Int) -> ClosedRange<String> {
        let count = dayCount(year: year, month: month)
        return dayKey(year: year, month: month, day: 1)...dayKey(year: year, month: month, day: count)
    }

    static func gridCells(year: Int, month: Int) -> [CalendarDayCell] {
        let firstWeekday = weekday(year: year, month: month, day: 1)
        let leadingEmptyCells = firstWeekday - 1
        let dayCount = dayCount(year: year, month: month)

        var cells = (0..<leadingEmptyCells).map { CalendarDayCell.empty(index: $0) }
        cells += (1...dayCount).map { day in
            CalendarDayCell(
                id: dayKey(year: year, month: month, day: day),
                day: day,
                localDayKey: dayKey(year: year, month: month, day: day)
            )
        }

        while cells.count % 7 != 0 {
            cells.append(.empty(index: cells.count))
        }

        return cells
    }

    static func dayKey(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func dayCount(year: Int, month: Int) -> Int {
        let calendar = Calendar.gregorianUTC
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private static func weekday(year: Int, month: Int, day: Int) -> Int {
        let calendar = Calendar.gregorianUTC
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
        return calendar.component(.weekday, from: date)
    }
}

struct CalendarDayCell: Identifiable, Equatable {
    let id: String
    let day: Int?
    let localDayKey: String?

    static func empty(index: Int) -> CalendarDayCell {
        CalendarDayCell(id: "empty-\(index)", day: nil, localDayKey: nil)
    }
}

extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }
}
