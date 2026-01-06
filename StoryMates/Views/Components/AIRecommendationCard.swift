import SwiftUI

struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Game Cover with Overlay
            CachedAsyncImage(url: recommendation.game.coverUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 200)
                    .clipped()
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 160, height: 200)
                    ProgressView()
                }
            }
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            )
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.0f%% Match", recommendation.score * 100))
                            .font(.custom("PressStart2P-Regular", size: 8))
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    .padding(8)
                }
            )
            
            // Description Area
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.game.name)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .lineLimit(1)
                
                Text(recommendation.reason)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .gray : .secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(width: 160, alignment: .leading)
            .background(themeManager.isDarkMode ? Color.black.opacity(0.6) : Color.white.opacity(0.9))
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple.opacity(0.5), .blue.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.purple.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}
