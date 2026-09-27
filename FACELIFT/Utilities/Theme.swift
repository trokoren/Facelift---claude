import SwiftUI

extension Color {
    /// Creates a color from a 24-bit sRGB hex value, e.g. `0xD4A0A0`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Colors sampled directly from the FACELIFT design files.
enum Palette {
    static let canvas = Color(hex: 0xFAF8F5)
    static let sheet = Color(hex: 0xFAF8F7)
    static let rose = Color(hex: 0xD4A0A0)
    static let roseLine = Color(hex: 0xEBCFCD)
    static let roseBorder = Color(hex: 0xEBD5D3)
    static let blush = Color(hex: 0xF5EBE8)
    static let chip = Color(hex: 0xF6EEEC)
    static let chipSoft = Color(hex: 0xF8F1EF)
    static let gold = Color(hex: 0xC4892B)
    static let sage = Color(hex: 0x3DAA6E)
    static let ember = Color(hex: 0xC4583B)
    static let sky = Color(hex: 0x3B8FC4)
    static let ink = Color(hex: 0x1C1210)
    static let body = Color(hex: 0x5A5452)
    static let stone = Color(hex: 0x8D8887)
    static let pebble = Color(hex: 0x999493)
    static let taupe = Color(hex: 0x9D9795)
    static let label = Color(hex: 0xA6A19E)
    static let quiet = Color(hex: 0xA9A5A4)
    static let mist = Color(hex: 0xABABAB)
    static let faint = Color(hex: 0xBFBDBC)
    static let whisper = Color(hex: 0xC9C5C3)
    static let tabIdle = Color(hex: 0xB5B2B1)
    static let hairline = Color(hex: 0xF2E6E4)
    static let divider = Color(hex: 0xEEEBE8)
    static let rowDivider = Color(hex: 0xF0EEEC)
    static let track = Color(hex: 0xEFEEEE)
    static let night = Color(hex: 0x0E0C0B)
    static let nightTrack = Color(hex: 0x211F1F)
    static let nightText = Color(hex: 0x787674)
    static let nightBody = Color(hex: 0xA7A5A3)
    static let nightDot = Color(hex: 0x997473)
}

/// Typography: Cormorant Garamond (editorial serif) + Plus Jakarta Sans (UI sans).
enum FLFont {
    enum Weight {
        case light, regular, medium, semibold, bold

        var postScriptName: String {
            switch self {
            case .light: "PlusJakartaSans-Light"
            case .regular: "PlusJakartaSans-Regular"
            case .medium: "PlusJakartaSans-Medium"
            case .semibold: "PlusJakartaSans-SemiBold"
            case .bold: "PlusJakartaSans-Bold"
            }
        }
    }

    static func sans(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    static func serif(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Regular", size: size)
    }

    static func serifMedium(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Medium", size: size)
    }

    static func serifItalic(_ size: CGFloat) -> Font {
        .custom("CormorantGaramondItalic-Italic", size: size)
    }
}
