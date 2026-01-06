import SwiftUI

struct MatchAnimationView: View {
    let user: User
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 30) {
                Text("It's a Match!")
                    .font(.custom("PressStart2P-Regular", size: 24))
                    .foregroundColor(.yellow)
                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                    
                    Text(String(user.name.prefix(2)).uppercased())
                        .font(.custom("PressStart2P-Regular", size: 36))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 10) {
                    Text(user.name)
                        .font(.custom("PressStart2P-Regular", size: 18))
                        .foregroundColor(.white)
                    
                    if let favoriteGame = user.favoriteGame {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                            Text(favoriteGame.name)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.yellow)
                    }
                }
                
                Button(action: {
                    dismissAnimation()
                }) {
                    Text("Keep Swiping")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .padding(.top, 20)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.5
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}
