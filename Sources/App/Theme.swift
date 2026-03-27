import SwiftUI

enum AppTheme {
    static let coral: Color = Color(dynamicLight: "#B71C1C", dynamicDark: "#FF8A80")
    static let mango: Color = Color(dynamicLight: "#E65100", dynamicDark: "#FFB74D")
    static let teal: Color = Color(dynamicLight: "#00695C", dynamicDark: "#64FFDA")
    static let ocean: Color = Color(dynamicLight: "#0D47A1", dynamicDark: "#82B1FF")
    static let sky: Color = Color(dynamicLight: "#E3F2FD", dynamicDark: "#0B1B2B")
    static let midnight: Color = Color(dynamicLight: "#0A0A0A", dynamicDark: "#000000")
    static let ink: Color = Color(dynamicLight: "#111827", dynamicDark: "#F5F7FA")
    static let cloud: Color = Color(dynamicLight: "#FFFFFF", dynamicDark: "#0E1116")

    static let background = LinearGradient(
        colors: [sky.opacity(0.95), cloud, mango.opacity(0.18)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [cloud.opacity(0.9), sky.opacity(0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [coral, mango],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func display(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-Heavy", size: size)
    }

    static func title(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-Bold", size: size)
    }

    static func body(_ size: CGFloat) -> Font {
        Font.custom("AvenirNext-Regular", size: size)
    }
}

extension Color {
    init(hex: String, alpha: Double = 1) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
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
            opacity: Double(a) / 255 * alpha
        )
    }

    init(dynamicLight lightHex: String, dynamicDark darkHex: String) {
        let provider: (UITraitCollection) -> UIColor = { traits in
            let isDark = traits.userInterfaceStyle == .dark
            return UIColor(Color(hex: isDark ? darkHex : lightHex))
        }
        self = Color(UIColor { provider($0) })
    }
}
