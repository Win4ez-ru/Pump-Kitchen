import SwiftUI

enum DSColor {
    static let ricePaper = Color(hex: 0xF5F0E6)
    static let graphite = Color(hex: 0x2B2B2B)
    static let matcha = Color(hex: 0x7A9B57)
    static let yuzu = Color(hex: 0xD8B347)
    static let inkMuted = Color(hex: 0x68645D)
    static let darkPaper = Color(hex: 0x161615)
    static let darkCard = Color(hex: 0x22211F)
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
}

