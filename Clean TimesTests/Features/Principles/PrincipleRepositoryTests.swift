import Foundation
import Testing
@testable import Clean_Times

@MainActor
struct PrincipleRepositoryTests {
    @Test func bundledJSONLoads() {
        let repository = PrincipleRepository()

        #expect(repository.allEntries().count == 366)
        #expect(repository.entry(month: 1, day: 1)?.keyword == "Wonder")
        #expect(repository.entry(month: 2, day: 29)?.title == "Moving through Recovery with Grace")
    }

    @Test func dateLookupReturnsExpectedEntry() {
        let repository = fixtureRepository
        let calendar = utcCalendar

        let entry = repository.entry(for: date(2026, 1, 2, calendar: calendar), calendar: calendar)

        #expect(entry.id == "01-02")
        #expect(entry.keyword == "Unity")
    }

    @Test func nextAndPreviousNavigateSortedEntries() {
        let repository = fixtureRepository

        #expect(repository.next(after: jan1).id == "01-02")
        #expect(repository.previous(before: jan2).id == "01-01")
    }

    @Test func navigationWrapsAtYearBoundaries() {
        let repository = fixtureRepository

        #expect(repository.previous(before: jan1).id == "12-31")
        #expect(repository.next(after: dec31).id == "01-01")
    }

    @Test func missingResourceFallsBackToSample() {
        let repository = PrincipleRepository(resourceName: "missing-principles")

        #expect(repository.allEntries() == [.sample])
    }

    @Test func jsonFixtureDecodesIntoPrincipleEntry() throws {
        let data = """
        [
          {
            "id": "06-01",
            "month": 6,
            "day": 1,
            "displayDate": "June 1",
            "keyword": "Love",
            "title": "Learning to Love Ourselves",
            "body": "Fixture body",
            "page": 154
          }
        ]
        """.data(using: .utf8)!

        let entries = try JSONDecoder().decode([PrincipleEntry].self, from: data)

        #expect(entries.first?.id == "06-01")
        #expect(entries.first?.page == 154)
    }

    private var fixtureRepository: PrincipleRepository {
        PrincipleRepository(entries: [dec31, jan2, jan1])
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var jan1: PrincipleEntry {
        PrincipleEntry(
            id: "01-01",
            month: 1,
            day: 1,
            displayDate: "January 1",
            keyword: "Wonder",
            title: "Recapturing a Sense of Wonder",
            body: "Fixture body",
            page: 2
        )
    }

    private var jan2: PrincipleEntry {
        PrincipleEntry(
            id: "01-02",
            month: 1,
            day: 2,
            displayDate: "January 2",
            keyword: "Unity",
            title: "Unity Keeps Us Coming Back",
            body: "Fixture body",
            page: 3
        )
    }

    private var dec31: PrincipleEntry {
        PrincipleEntry(
            id: "12-31",
            month: 12,
            day: 31,
            displayDate: "December 31",
            keyword: "Compassion",
            title: "The Compassion of Tradition Three",
            body: "Fixture body",
            page: 378
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) -> Date {
        DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day).date!
    }
}
