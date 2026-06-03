import Foundation

struct CleanTimeSnapshot: Equatable {
    let cleanDate: Date
    let today: Date
    let ordinalDay: Int
    let completedDays: Int
    let collapsedLabel: String
    let headline: String
    let detail: String
}

enum CleanTimeCalculator {
    static let earlyRecoveryMessages: [String] = [
        "Stay close to today.",
        "One day at a time is enough.",
        "Keep the next right action small.",
        "Reach out before the day gets heavy.",
        "Let the clean time be simple.",
        "Protect the quiet progress.",
        "Come back to the present moment."
    ]

    static func snapshot(
        cleanDate: Date,
        today: Date = .now,
        calendar: Calendar = .current
    ) -> CleanTimeSnapshot {
        let cleanStart = calendar.startOfDay(for: cleanDate)
        let todayStart = calendar.startOfDay(for: today)
        let dayDifference = calendar.dateComponents([.day], from: cleanStart, to: todayStart).day ?? 0
        let ordinalDay = max(dayDifference + 1, 1)
        let completedDays = max(ordinalDay - 1, 0)

        return CleanTimeSnapshot(
            cleanDate: cleanStart,
            today: todayStart,
            ordinalDay: ordinalDay,
            completedDays: completedDays,
            collapsedLabel: "\(ordinalDay)d",
            headline: "Today is day \(ordinalDay)",
            detail: detail(
                ordinalDay: ordinalDay,
                cleanStart: cleanStart,
                todayStart: todayStart,
                calendar: calendar
            )
        )
    }

    private static func detail(
        ordinalDay: Int,
        cleanStart: Date,
        todayStart: Date,
        calendar: Calendar
    ) -> String {
        if ordinalDay <= earlyRecoveryMessages.count {
            return earlyRecoveryMessages[ordinalDay - 1]
        }

        return completedDuration(from: cleanStart, to: todayStart, calendar: calendar)
    }

    private static func completedDuration(from startDate: Date, to endDate: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: startDate, to: endDate)
        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let remainingDays = max(components.day ?? 0, 0)
        let weeks = remainingDays / 7
        let days = remainingDays % 7

        var parts: [String] = []
        append(years, singular: "year", plural: "years", to: &parts)
        append(months, singular: "month", plural: "months", to: &parts)
        append(weeks, singular: "week", plural: "weeks", to: &parts)
        append(days, singular: "day", plural: "days", to: &parts)

        return parts.isEmpty ? "0 days" : parts.joined(separator: ", ")
    }

    private static func append(_ value: Int, singular: String, plural: String, to parts: inout [String]) {
        guard value > 0 else { return }
        parts.append("\(value) \(value == 1 ? singular : plural)")
    }
}
