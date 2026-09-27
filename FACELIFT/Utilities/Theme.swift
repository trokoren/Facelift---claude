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

/// Colors sampled from the FACELIFT design files. Greys were darkened for legibility on the
/// cream canvas (secondary text went from about 2:1 to 3.7-5:1 contrast).
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
    static let body = Color(hex: 0x4A4442)
    static let stone = Color(hex: 0x6F6967)
    static let pebble = Color(hex: 0x767170)
    static let taupe = Color(hex: 0x7C7674)
    static let label = Color(hex: 0x837D7B)
    static let quiet = Color(hex: 0x8C8786)
    static let mist = Color(hex: 0x858080)
    static let faint = Color(hex: 0x9E9998)
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
        .custom(weight.postScriptName, size: readable(size))
    }

    /// Nudges the tiniest UI text up so nothing in the app reads below ~11.5pt.
    /// Sizes 15pt and above are untouched.
    private static func readable(_ size: CGFloat) -> CGFloat {
        switch size {
        case ..<11: size + 2
        case ..<13: size + 1.5
        case ..<15: size + 0.5
        default: size
        }
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
