import SwiftUI

// MARK: - Pixel Container Assets (Simplified)
struct PixelBackground: View {
    var fillColor: Color = Color(red: 254/255, green: 238/255, blue: 176/255) // Default to Beige
    var borderColor: Color = .black
    var lineWidth: CGFloat = 2
    var shadowOffset: CGFloat = 4
    
    var body: some View {
        ZStack {
            // Shadow (Offset)
            Rectangle()
                .fill(Color.black)
                .offset(x: shadowOffset, y: shadowOffset)
            
            // Main Body
            Rectangle()
                .fill(fillColor)
                .overlay(
                    Rectangle()
                        .stroke(borderColor, lineWidth: lineWidth)
                )
        }
    }
}
