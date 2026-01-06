import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var authManager = AuthManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            if themeManager.isDarkMode {
                DarkThemeBackground()
            } else {
                Image("background_land")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.isDarkMode ? .white : .gray)
                        TextField("Search games...", text: $viewModel.searchText)
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                            .onSubmit {
                                viewModel.performSearch()
                            }
                    }
                    .padding(10)
                    .background(themeManager.isDarkMode ? Color.black.opacity(0.6) : Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.isDarkMode ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.isDarkMode ? .white : .gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Increased top padding for Dynamic Island
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        if viewModel.isSearching {
                            Text("Search Results")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                                ForEach(viewModel.searchResults) { game in
                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                        GamePosterView(game: game)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // AI Recommendations Section
                            if !viewModel.aiRecommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.yellow)
                                        Text("AI Picks for You")
                                            .font(.custom("PressStart2P-Regular", size: 16))
                                            .foregroundColor(themeManager.isDarkMode ? .white : .white)
                                            .shadow(color: .black, radius: 2, x: 1, y: 1)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            ForEach(viewModel.aiRecommendations) { rec in
                                                NavigationLink(destination: GameDetailsView(gameId: rec.game.id)) {
                                                    AIRecommendationCard(recommendation: rec)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.top, 10)
                            }
                            
                            // Sections

                            ForEach(viewModel.sections, id: \.self) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section)
                                        .font(.custom("PressStart2P-Regular", size: 16))
                                        .foregroundColor(themeManager.isDarkMode ? .white : .white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            if section == "Popular Games" {
                                                ForEach(viewModel.popularGames) { game in
                                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                                        GamePosterView(game: game)
                                                    }
                                                }
                                            } else {
                                                ForEach(viewModel.genreGames[section] ?? []) { game in
                                                    NavigationLink(destination: GameDetailsView(gameId: game.id)) {
                                                        GamePosterView(game: game)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 140) // Increase bottom padding for floating tab bar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(destination: MyCollectionView()) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(Color.yellow) // PrimaryGold equivalent
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
                }
            }
        )
    }
}

struct GamePosterView: View {
    let game: Game
    
    var body: some View {
        VStack {
            // Game Poster with caching, smaller size and card-like styling
            CachedAsyncImage(url: game.coverUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 150) // Adjust size here for card-like image
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 100, height: 150) // Match the size of the image
                        .cornerRadius(10)
                    ProgressView()
                }
            }
            
            Text(game.name)
                .font(.custom("PressStart2P-Regular", size: 10))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .lineLimit(1)
                .frame(maxWidth: 100) // Constrain text width for card-like effect
        }
        .frame(width: 100) // Constrain the card size
        .padding(5)
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
