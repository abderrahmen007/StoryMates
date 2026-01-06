import SwiftUI

struct ArtStyleSelector: View {
    @Binding var selectedStyle: ArtStyle
    @Binding var selectedDimension: ArtDimension
    let onSave: () -> Void
    
    private let pixelAccent = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🎨 PROJECT ART STYLE")
                .font(.custom("Courier", size: 18).weight(.bold))
                .foregroundColor(.white)
            
            // Dimension Toggle
            HStack(spacing: 0) {
                DimensionButton(
                    title: "2D",
                    isActive: selectedDimension == .TWO_D,
                    action: { selectedDimension = .TWO_D }
                )
                
                DimensionButton(
                    title: "3D",
                    isActive: selectedDimension == .THREE_D,
                    action: { selectedDimension = .THREE_D }
                )
            }
            .padding(4)
            .background(Color.black.opacity(0.3))
            .border(Color.white.opacity(0.2), width: 2)
            
            // Style Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredStyles, id: \.self) { style in
                        StyleCard(
                            style: style,
                            isSelected: selectedStyle == style,
                            action: { selectedStyle = style }
                        )
                    }
                }
                .padding(4)
            }
            .frame(maxHeight: 300)
            
            Button(action: onSave) {
                Text("APPLY STYLE")
                    .font(.custom("Courier", size: 16).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pixelAccent)
                    .foregroundColor(.black)
                    .border(Color.black, width: 2)
            }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.25))
        .border(pixelAccent, width: 4)
    }
    
    private var filteredStyles: [ArtStyle] {
        if selectedDimension == .TWO_D {
            return [.PIXEL_ART, .STANDARD_2D]
        } else {
            return [.LOW_POLY, .REALISTIC]
        }
    }
}

struct DimensionButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Courier", size: 14).weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isActive ? Color.pixelHighlight : Color.clear)
                .foregroundColor(isActive ? .black : .white)
        }
    }
}

struct StyleCard: View {
    let style: ArtStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(styleIcon(style))
                    .font(.system(size: 32))
                Text(style.displayName)
                    .font(.custom("Courier", size: 10).weight(.bold))
                    .foregroundColor(isSelected ? .black : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.pixelGold : Color.white.opacity(0.1))
            .border(isSelected ? Color.white : Color.clear, width: 2)
        }
    }
    
    private func styleIcon(_ style: ArtStyle) -> String {
        switch style {
        case .PIXEL_ART: return "👾"
        case .STANDARD_2D: return "🎨"
        case .LOW_POLY: return "📐"
        case .REALISTIC: return "📸"
        }
    }
}
