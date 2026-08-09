import XCTest
@testable import MyWords

final class DailyDrawPolicyTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "ja_JP")
        return value
    }

    func testSameLocalDayIsShownOnlyOnce() throws {
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let first = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 13, hour: 8)))
        let second = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 13, hour: 23, minute: 59)))
        let key = DailyDrawPolicy.dateKey(for: first, calendar: calendar, timeZone: tokyo)
        XCTAssertFalse(DailyDrawPolicy.shouldPresent(lastPresentedDate: key, now: second, calendar: calendar, timeZone: tokyo))
    }

    func testMidnightBoundaryStartsNewDraw() throws {
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let before = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 13, hour: 23, minute: 59)))
        let after = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 14, hour: 0, minute: 1)))
        let key = DailyDrawPolicy.dateKey(for: before, calendar: calendar, timeZone: tokyo)
        XCTAssertTrue(DailyDrawPolicy.shouldPresent(lastPresentedDate: key, now: after, calendar: calendar, timeZone: tokyo))
    }

    func testTimeZoneUsesUsersLocalDay() throws {
        let utc = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: utc, year: 2026, month: 7, day: 13, hour: 16)))
        XCTAssertEqual(DailyDrawPolicy.dateKey(for: date, calendar: calendar, timeZone: utc), "2026-07-13")
        XCTAssertEqual(DailyDrawPolicy.dateKey(for: date, calendar: calendar, timeZone: tokyo), "2026-07-14")
    }

    func testNightWindowIncludesLateNightAndEarlyMorning() throws {
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let late = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 13, hour: 21)))
        let early = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 14, hour: 1)))
        let day = try XCTUnwrap(calendar.date(from: DateComponents(timeZone: tokyo, year: 2026, month: 7, day: 14, hour: 12)))
        XCTAssertTrue(DailyDrawPolicy.isNight(late, calendar: calendar, timeZone: tokyo))
        XCTAssertTrue(DailyDrawPolicy.isNight(early, calendar: calendar, timeZone: tokyo))
        XCTAssertFalse(DailyDrawPolicy.isNight(day, calendar: calendar, timeZone: tokyo))
    }

    func testDailyCardArtworkFollowsTimeOfDay() throws {
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        var localCalendar = calendar
        localCalendar.timeZone = tokyo

        let dawn = try XCTUnwrap(localCalendar.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 7)))
        let day = try XCTUnwrap(localCalendar.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 12)))
        let dusk = try XCTUnwrap(localCalendar.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 18)))
        let night = try XCTUnwrap(localCalendar.date(from: DateComponents(year: 2026, month: 7, day: 16, hour: 23)))

        XCTAssertEqual(DailyCardArtwork.resolve(for: dawn, calendar: localCalendar), .dawn)
        XCTAssertEqual(DailyCardArtwork.resolve(for: day, calendar: localCalendar), .day)
        XCTAssertEqual(DailyCardArtwork.resolve(for: dusk, calendar: localCalendar), .dusk)
        XCTAssertEqual(DailyCardArtwork.resolve(for: night, calendar: localCalendar), .night)
        XCTAssertEqual(DailyCardArtwork.resolve(for: day, calendar: localCalendar, forceNight: true), .night)
    }

    func testInsightSuggestionIsExactlyEveryThirdEligibleSave() {
        XCTAssertEqual((1...9).filter(ExperimentAssignmentService.shouldShowInsight), [3, 6, 9])
    }
}
