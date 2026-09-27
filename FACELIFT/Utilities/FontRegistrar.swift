import Foundation
import CoreText

/// Registers the bundled TTF fonts for this process so they can be used by name.
enum FontRegistrar {
    static func registerAll() {
        let rootFonts = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        let folderFonts = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? []
        for url in rootFonts + folderFonts {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
