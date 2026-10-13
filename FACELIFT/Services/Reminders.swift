import Foundation
import UserNotifications

/// The day and time she picked for her weekly check-in (onboarding notifications step).
/// Saved on this phone. Defaults to Sunday morning.
enum ReminderTime {
    /// Calendar weekday numbers: 1 is Sunday.
    static let days: [(label: String, value: Int)] = [("Sun", 1), ("Mon", 2), ("Wed", 4), ("Sat", 7)]
    static let times: [(label: String, value: Int)] = [("Morning", 9), ("Evening", 19)]

    static var weekday: Int { UserDefaults.standard.object(forKey: "facelift.reminderWeekday") as? Int ?? 1 }
    static var hour: Int { UserDefaults.standard.object(forKey: "facelift.reminderHour") as? Int ?? 9 }

    static func save(weekday: Int, hour: Int) {
        UserDefaults.standard.set(weekday, forKey: "facelift.reminderWeekday")
        UserDefaults.standard.set(hour, forKey: "facelift.reminderHour")
    }

    /// "Sun 9:00 AM"
    static func label(weekday: Int, hour: Int) -> String {
        let day = days.first { $0.value == weekday }?.label ?? "Sun"
        return "\(day) \(hour > 12 ? hour - 12 : hour):00 \(hour >= 12 ? "PM" : "AM")"
    }
}

/// Reminders scheduled on her phone (no server needed):
/// - Weekly scan: on the day and time she picked, at least 5 days after her last scan.
///   Moves forward every time she scans.
/// - Trial heads-up: the day before her free trial becomes a paid membership.
/// Rescheduled whenever something changes (launch, a new scan, the switch, her membership).
enum Reminders {
    static let scanID = "facelift.scan-reminder"
    static let trialID = "facelift.trial-ending"

    static func update(lastScan: Date?, scanRemindersOn: Bool, trialEnds: Date?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [scanID, trialID])
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        if scanRemindersOn {
            let earliest = max((lastScan ?? Date()).addingTimeInterval(5 * 86_400), Date().addingTimeInterval(60))
            if let when = Calendar.current.nextDate(
                after: earliest,
                matching: DateComponents(hour: ReminderTime.hour, minute: 0, weekday: ReminderTime.weekday),
                matchingPolicy: .nextTime
            ) {
                await add(
                    id: scanID,
                    title: "Time for your weekly scan",
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
