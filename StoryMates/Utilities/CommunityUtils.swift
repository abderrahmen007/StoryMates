import SwiftUI

struct PixelArtTheme {
    static let black = Color(hex: "2D1B2E")
    static let white = Color(hex: "E0F8CF")
    static let green = Color(hex: "57C495")
    static let blue = Color(hex: "4D9BE6")
    static let red = Color(hex: "E64D4D")
    static let gray = Color(hex: "8B9BB4")
    
    static func font(size: CGFloat) -> Font {
        return .custom("PressStart2P-Regular", size: size)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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

struct PixelBorder: ViewModifier {
    var width: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    ZStack {
                        // Top
                        Rectangle()
                            .fill(PixelArtTheme.black)
                            .frame(height: width)
                            .offset(y: -(width / 2))
                        // Bottom
                        Rectangle()
                            .fill(PixelArtTheme.black)
                            .frame(height: width)
                            .offset(y: geo.size.height - (width / 2))
                        // Left
                        Rectangle()
                            .fill(PixelArtTheme.black)
                            .frame(width: width)
                            .offset(x: -(width / 2))
                        // Right
                        Rectangle()
                            .fill(PixelArtTheme.black)
                            .frame(width: width)
                            .offset(x: geo.size.width - (width / 2))
                    }
                }
            )
    }
}

extension View {
    func pixelBorder(width: CGFloat = 4) -> some View {
        modifier(PixelBorder(width: width))
    }
}
