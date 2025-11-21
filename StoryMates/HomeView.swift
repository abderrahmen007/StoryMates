import SwiftUI

struct HomeView: View {
    @State private var searchText = ""
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var networkManager = NetworkManager()
    
    @State private var popularGames: [Game] = []
    @State private var genreGames: [String: [Game]] = [:]
    @State private var searchResults: [Game] = []
    @State private var isSearching = false
    
    let sections = ["Popular Games", "Action", "Adventure", "RPG", "Strategy", "Puzzle"]
    
    var body: some View {
        ZStack {
            // Background
            Image("background_land")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search games...", text: $searchText)
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.black)
                            .onSubmit {
                                performSearch()
                            }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50) // Adjust for safe area
                .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        if isSearching {
                            Text("Search Results")
                                .font(.custom("PressStart2P-Regular", size: 16))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                                ForEach(searchResults) { game in
                                    GamePosterView(game: game)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Sections
                            ForEach(sections, id: \.self) { section in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(section)
                                        .font(.custom("PressStart2P-Regular", size: 16))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 15) {
                                            if section == "Popular Games" {
                                                ForEach(popularGames) { game in
                                                    GamePosterView(game: game)
                                                }
                                            } else {
                                                ForEach(genreGames[section] ?? []) { game in
                                                    GamePosterView(game: game)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        do {
            // Fetch popular games
            popularGames = try await networkManager.fetchPopularGames()
            
            // Fetch genre games
            for section in sections where section != "Popular Games" {
                let games = try await networkManager.fetchGamesByGenre(genre: section)
                genreGames[section] = games
            }
        } catch {
            print("Error fetching games: \(error)")
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        Task {
            do {
                searchResults = try await networkManager.searchGames(query: searchText)
            } catch {
                print("Error searching games: \(error)")
            }
        }
    }
}

struct GamePosterView: View {
    let game: Game
    
    var body: some View {
        VStack {
            // Game Poster
            AsyncImage(url: game.coverUrl) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 120, height: 160)
                            .cornerRadius(10)
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 160)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                case .failure:
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 120, height: 160)
                            .cornerRadius(10)
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(.white)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(game.name)
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
