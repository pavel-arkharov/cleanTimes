import Foundation
import Testing
@testable import Clean_Times

@MainActor
struct CleanTimeCalculatorTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func cleanDateTodayIsDayOne() {
        let calendar = utcCalendar
        let today = date(2026, 6, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: today, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 1)
        #expect(snapshot.completedDays == 0)
        #expect(snapshot.collapsedLabel == "1d")
        #expect(snapshot.headline == "Today is day 1")
    }

    @Test func cleanDateYesterdayIsDayTwo() {
        let calendar = utcCalendar
        let cleanDate = date(2026, 5, 31, calendar: calendar)
        let today = date(2026, 6, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 2)
        #expect(snapshot.completedDays == 1)
        #expect(snapshot.collapsedLabel == "2d")
        #expect(snapshot.headline == "Today is day 2")
    }

    @Test func dayEightShowsOneWeek() {
        let calendar = utcCalendar
        let cleanDate = date(2026, 5, 25, calendar: calendar)
        let today = date(2026, 6, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 8)
        #expect(snapshot.completedDays == 7)
        #expect(snapshot.detail == "1 week")
    }

    @Test func monthBoundaryCountsStartOfDay() {
        let calendar = utcCalendar
        let cleanDate = date(2026, 1, 31, calendar: calendar)
        let today = date(2026, 2, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 2)
    }

    @Test func yearBoundaryCountsStartOfDay() {
        let calendar = utcCalendar
        let cleanDate = date(2025, 12, 31, calendar: calendar)
        let today = date(2026, 1, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 2)
    }

    @Test func leapYearCountsFebruaryTwentyNine() {
        let calendar = utcCalendar
        let cleanDate = date(2024, 2, 28, calendar: calendar)
        let today = date(2024, 3, 1, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 3)
        #expect(snapshot.completedDays == 2)
    }

    @Test func daylightSavingBoundaryCountsCalendarDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let cleanDate = date(2024, 3, 9, calendar: calendar)
        let today = date(2024, 3, 11, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.ordinalDay == 3)
    }

    @Test func laterDurationUsesCalendarComponents() {
        let calendar = utcCalendar
        let cleanDate = date(2021, 6, 1, calendar: calendar)
        let today = date(2025, 5, 3, calendar: calendar)

        let snapshot = CleanTimeCalculator.snapshot(cleanDate: cleanDate, today: today, calendar: calendar)

        #expect(snapshot.detail == "3 years, 11 months, 2 days")
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day).date!
    }
}
