import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @StateObject private var authManager = AuthManager.shared
    
    let sections = ["Your Games", "Popular Games", "Action", "Adventure", "RPG", "Strategy", "Puzzle"]
    
    var body: some View {
        ZStack {
            // Background
            Image("background_land")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            // Cloud animation (optional, if available)
            AnimatedClouds() 
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search games...", text: $searchText)
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.black)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    
                    Button(action: {
                        // Search action
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.yellow)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50) // Adjust for safe area
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        ForEach(sections, id: \.self) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section)
                                    .font(.custom("PressStart2P-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(0..<5) { index in
                                            GamePosterView(index: index)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct GamePosterView: View {
    let index: Int
    
    var body: some View {
        VStack {
            // Placeholder for Game Poster
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 120, height: 160)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Image(systemName: "gamecontroller.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
            
            Text("Game \(index + 1)")
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .lineLimit(1)
                .frame(width: 120)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
