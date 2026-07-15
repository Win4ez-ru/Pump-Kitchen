import SwiftUI
import UIKit

enum DSColor {
    static let background = Color(light: 0xF7F8FA, dark: 0x101114)
    static let secondaryBackground = Color(light: 0xEEF1F5, dark: 0x191B20)
    static let card = Color(light: 0xFCFCFD, dark: 0x22242A)
    static let elevatedCard = Color(light: 0xEEF3F8, dark: 0x2A2D34)
    static let tabBar = Color(light: 0xFAFBFC, dark: 0x1D2026)
    static let accent = Color(light: 0x6F8FB4, dark: 0x9BB7D5)
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x0F1720)
    static let accentSurface = Color(light: 0xE7EEF7, dark: 0x202A36)
    static let accentCard = Color(light: 0xF0F5FA, dark: 0x1D2631)
    static let accentStroke = Color(light: 0xB9C9DC, dark: 0x60758D)
    static let border = Color(light: 0xDDE3EA, dark: 0x373B43)
    static let screenBorder = Color(light: 0xE7ECF2, dark: 0x2E3239)
    static let textPrimary = Color(light: 0x15171A, dark: 0xF8FAFC)
    static let textSecondary = Color(light: 0x5F6670, dark: 0xAEB5BF)
    static let textTertiary = Color(light: 0x9099A5, dark: 0x78818D)
    static let success = Color(light: 0x1F8A3A, dark: 0x34C759)
    static let destructive = Color(light: 0xC73434, dark: 0xFF453A)
    static let destructiveSurface = Color(light: 0xF8E3E3, dark: 0x2A1616)
    static let destructiveStroke = Color(light: 0xE4A5A5, dark: 0x673030)
    static let editorialLavender = Color(light: 0xDCE3EE, dark: 0x252B35)
    static let foodBase = Color(light: 0xE8DDAE, dark: 0xD3DA95)
    static let foodGreens = Color(light: 0x7F9E82, dark: 0x9DBB7A)
    static let foodProtein = Color(hex: 0xF2C078)
    static let foodAccent = Color(hex: 0xFF7A59)

    static let ricePaper = background
    static let graphite = textPrimary
    static let matcha = accent
    static let yuzu = accent
    static let inkMuted = textSecondary
    static let darkPaper = background
    static let darkCard = card
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt, dark: UInt, alpha: Double = 1) {
        self.init(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: alpha)
                    : UIColor(hex: light, alpha: alpha)
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
