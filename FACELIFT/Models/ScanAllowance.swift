import Foundation

/// Scans per day. Two a day, four on her very first day so she can try it freely. The second
/// scan of a day gets a gentle "you've already scanned" note; past the limit, the next scan
/// unlocks tomorrow. Only finished scans count: a scan that couldn't be read never does, and
/// deleting a scan doesn't give one back. Saved on this phone.
enum ScanAllowance {
    case open
    /// She's already scanned today, but can still go ahead.
    case alreadyScanned
    /// Today's scans are used up.
    case usedUp

    private static let dayKey = "facelift.scanAllowance.day"
    private static let countKey = "facelift.scanAllowance.count"
    private static let firstDayKey = "facelift.scanAllowance.firstDay"

    private static func today() -> String {
        Date().formatted(.iso8601.year().month().day())
    }

    private static var countToday: Int {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: dayKey) == today() ? defaults.integer(forKey: countKey) : 0
    }

    private static var isFirstDay: Bool {
        guard let first = UserDefaults.standard.string(forKey: firstDayKey) else { return true }
        return first == today()
    }

    static var current: ScanAllowance {
        let count = countToday
        let limit = isFirstDay ? 4 : 2
        if count >= limit { return .usedUp }
        if count >= 1 && !isFirstDay { return .alreadyScanned }
        return .open
    }

    /// Call once a scan has been read successfully.
    static func recordScan() {
        let defaults = UserDefaults.standard
        let day = today()
        if defaults.string(forKey: firstDayKey) == nil { defaults.set(day, forKey: firstDayKey) }
        defaults.set(countToday + 1, forKey: countKey)
        defaults.set(day, forKey: dayKey)
    }
}
