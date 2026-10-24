import Foundation
import UserNotifications

/// The days and time she picked for her scan reminders (onboarding notifications step).
/// Saved on this phone. Defaults to Sunday morning. She can pick any number of days.
enum ReminderTime {
    /// Calendar weekday numbers: 1 is Sunday.
    static let days: [(label: String, value: Int)] = [
        ("Sun", 1), ("Mon", 2), ("Tue", 3), ("Wed", 4), ("Thu", 5), ("Fri", 6), ("Sat", 7),
    ]
    static let times: [(label: String, value: Int)] = [("Morning, 8 AM", 8), ("Evening, 8 PM", 20)]

    /// Her days, in week order. Earlier builds saved a single day; that carries over.
    static var weekdays: [Int] {
        if let saved = UserDefaults.standard.array(forKey: "facelift.reminderWeekdays") as? [Int], !saved.isEmpty {
            return saved.sorted()
        }
        return [UserDefaults.standard.object(forKey: "facelift.reminderWeekday") as? Int ?? 1]
    }

    /// Morning or evening. Earlier builds saved 9 AM or 7 PM; those map to the nearest option.
    static var hour: Int {
        let saved = UserDefaults.standard.object(forKey: "facelift.reminderHour") as? Int ?? 8
        return saved < 12 ? 8 : 20
    }

    static func save(weekdays: [Int], hour: Int) {
        UserDefaults.standard.set(weekdays.sorted(), forKey: "facelift.reminderWeekdays")
        UserDefaults.standard.set(hour, forKey: "facelift.reminderHour")
    }

    static func dayLabel(_ weekday: Int) -> String {
        days.first { $0.value == weekday }?.label ?? "Sun"
    }

    /// The soonest of her days from today, for the preview.
    static func nextDay(of weekdays: [Int], from date: Date = Date()) -> Int {
        let today = Calendar.current.component(.weekday, from: date)
        return weekdays.min { ($0 - today + 7) % 7 < ($1 - today + 7) % 7 } ?? 1
    }

    /// "Sun 8:00 AM"
    static func label(weekday: Int, hour: Int) -> String {
        "\(dayLabel(weekday)) \(hour > 12 ? hour - 12 : hour):00 \(hour >= 12 ? "PM" : "AM")"
    }

    /// One day a week is a weekly scan; more days is just a scan.
    static func reminderTitle(dayCount: Int) -> String {
        dayCount == 1 ? "Time for your weekly scan" : "Time for your skin scan"
    }
}

/// Reminders scheduled on her phone (no server needed):
/// - Scan: on each day she picked, at her time. With one day a week it waits at least 5 days
///   after her last scan; with more days, at least a day. Moves forward every time she scans.
/// - Trial heads-up: the day before her free trial becomes a paid membership.
/// Rescheduled whenever something changes (launch, a new scan, the switch, her membership).
enum Reminders {
    static let scanID = "facelift.scan-reminder"
    static let trialID = "facelift.trial-ending"

    static func update(lastScan: Date?, scanRemindersOn: Bool, trialEnds: Date?) async {
        let center = UNUserNotificationCenter.current()
        let scanIDs = [scanID] + ReminderTime.days.map { "\(scanID)-\($0.value)" }
        center.removePendingNotificationRequests(withIdentifiers: scanIDs + [trialID])
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        if scanRemindersOn {
            let weekdays = ReminderTime.weekdays
            let gap: TimeInterval = weekdays.count == 1 ? 5 * 86_400 : 86_400
            let earliest = max((lastScan ?? Date()).addingTimeInterval(gap), Date().addingTimeInterval(60))
            for weekday in weekdays {
                guard let when = Calendar.current.nextDate(
                    after: earliest,
                    matching: DateComponents(hour: ReminderTime.hour, minute: 0, weekday: weekday),
                    matchingPolicy: .nextTime
                ) else { continue }
                await add(
                    id: "\(scanID)-\(weekday)",
                    title: ReminderTime.reminderTitle(dayCount: weekdays.count),
                    body: "Same light, same spot. Let's see how your skin is doing this week.",
                    at: when
                )
            }
        }

        if let end = trialEnds {
            let heads = end.addingTimeInterval(-86_400)
            if heads > Date().addingTimeInterval(10 * 60) {
                await add(
                    id: trialID,
                    title: "Your free trial ends tomorrow",
                    body: "Your membership begins tomorrow. You can manage or cancel it anytime in Settings.",
                    at: heads
                )
            }
        }
    }

    private static func add(id: String, title: String, body: String, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: id, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
