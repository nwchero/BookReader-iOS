import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AppTheme {
    static let primary = Color(hex: "4A90D9")
    static let primaryDark = Color(hex: "357ABD")
    static let accent = Color(hex: "FF6F00")
    static let readerBackgroundLight = Color(hex: "F5F5DC")
    static let readerBackgroundDark = Color(hex: "1A1A2E")
    static let readerTextPrimary = Color(hex: "333333")

    struct ReaderFont {
        static var defaultSize: CGFloat { 18 }
        static var minSize: CGFloat { 12 }
        static var maxSize: CGFloat { 32 }

        static func body(size: CGFloat) -> Font {
            .system(size: size, design: .serif)
        }

        static func title(size: CGFloat) -> Font {
            .system(size: size + 4, weight: .semibold, design: .serif)
        }
    }
}
