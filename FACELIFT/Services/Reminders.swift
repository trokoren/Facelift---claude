import Foundation
import UserNotifications

/// Reminders scheduled on her phone (no server needed):
/// - Weekly scan: 10am, 7 days after her last scan. Moves forward every time she scans.
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
            let due = (lastScan ?? Date()).addingTimeInterval(7 * 86_400)
            await add(
                id: scanID,
                title: "Time for your weekly scan",
                body: "Same light, same spot. Let's see how your skin is doing this week.",
                at: morning(onOrAfter: due)
            )
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

    /// 10am on that day, or 10am the next day if that has already passed.
    private static func morning(onOrAfter date: Date) -> Date {
        let calendar = Calendar.current
        var target = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date
        if target < date { target = calendar.date(byAdding: .day, value: 1, to: target) ?? target }
        if target < Date().addingTimeInterval(60) {
            target = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date().addingTimeInterval(86_400)) ?? target
        }
        return target
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
