import Foundation

enum DailyDrawPolicy {
    static func dateKey(for date: Date, calendar: Calendar = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        var calendar = calendar
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func shouldPresent(lastPresentedDate: String, now: Date = Date(), calendar: Calendar = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> Bool {
        lastPresentedDate != dateKey(for: now, calendar: calendar, timeZone: timeZone)
    }

    static func isNight(_ date: Date = Date(), calendar: Calendar = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> Bool {
        var calendar = calendar
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return hour >= 21 || hour < 5
    }
}
