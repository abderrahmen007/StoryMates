import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var showingEditProfile = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Edit fields
    @Published var editedPsn = ""
    @Published var editedXbox = ""
    @Published var editedSteam = ""
    @Published var editedDiscord = ""
    @Published var editedNintendo = ""
    @Published var editedAvailability = ""
    @Published var editedBio = ""
    @Published var selectedPlayStyles: Set<String> = []
    @Published var selectedLanguages: Set<String> = []
    @Published var editedFavoriteGame: FavoriteGame?
    
    // Search state
    @Published var searchText = ""
    @Published var searchResults: [Game] = []
    @Published var isSearching = false
    
    private var authManager = AuthManager.shared
    private var networkManager = NetworkManager()
    
    let availablePlayStyles = ["Casual", "Competitive", "Speedrunner", "Completionist", "Roleplayer", "Social"]
    let availableLanguages = ["English", "Spanish", "French", "German", "Japanese", "Korean", "Chinese"]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                Task {
                    await self.searchGames(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchProfile() async {
        guard let userId = authManager.userId else {
            print("❌ No userId found in authManager")
            return
        }
        
        print("🔄 Fetching profile for userId: \(userId)")
        isLoading = true
        do {
            // Record login for daily streak/XP
            do {
                let streakResponse = try await GamificationService.shared.recordLogin(userId: userId)
                print("🔥 Streak updated: \(streakResponse.streak) days, +\(streakResponse.xpAwarded) XP")
            } catch {
                print("⚠️ Streak update failed (non-fatal): \(error)")
            }
            
            let fetchedUser = try await networkManager.fetchUser(id: userId)
            print("✅ Profile fetched successfully: \(fetchedUser.name)")
            print("📊 Stats - Level: \(fetchedUser.stats?.level ?? 0), XP: \(fetchedUser.stats?.xp ?? 0)")
            self.user = fetchedUser
            self.populateEditFields(user: fetchedUser)
        } catch {
            print("❌ Error fetching profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func populateEditFields(user: User) {
        editedPsn = user.gamerTags?.psn ?? ""
        editedXbox = user.gamerTags?.xbox ?? ""
        editedSteam = user.gamerTags?.steam ?? ""
        editedDiscord = user.gamerTags?.discord ?? ""
        editedNintendo = user.gamerTags?.nintendo ?? ""
        editedAvailability = user.availability ?? ""
        editedBio = user.bio ?? ""
        selectedPlayStyles = Set(user.playStyles ?? [])
        selectedLanguages = Set(user.languages ?? [])
        editedFavoriteGame = user.favoriteGame
        print("📝 Edit fields populated")
    }
    
    func searchGames(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        do {
            let games = try await networkManager.searchGames(query: query)
            searchResults = games
        } catch {
            print("Search error: \(error)")
        }
        isSearching = false
    }
    
    func saveProfile() async {
        guard let userId = authManager.userId else {
            print("❌ No userId found for save")
            return
        }
        
        print("💾 Saving profile for userId: \(userId)")
        isLoading = true
        
        let gamerTags: [String: String] = [
            "psn": editedPsn,
            "xbox": editedXbox,
            "steam": editedSteam,
            "discord": editedDiscord,
            "nintendo": editedNintendo
        ]
        
        var updateData: [String: Any] = [
            "gamerTags": gamerTags,
            "playStyles": Array(selectedPlayStyles),
            "availability": editedAvailability,
            "bio": editedBio,
            "languages": Array(selectedLanguages)
        ]
        
        if let favoriteGame = editedFavoriteGame {
            let favoriteGameData: [String: Any] = [
                "gameId": favoriteGame.gameId,
                "name": favoriteGame.name,
                "coverUrl": favoriteGame.coverUrl
            ]
            updateData["favoriteGame"] = favoriteGameData
        }
        
        print("📤 Update data: \(updateData)")
        
        do {
            let updatedUser = try await networkManager.updateUser(id: userId, data: updateData)
            print("✅ Profile saved successfully")
            self.user = updatedUser
            showingEditProfile = false
        } catch {
            print("❌ Error saving profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    
    func logout() {
        authManager.logout()
    }
    
    // MARK: - Computed Properties
    
    // Helper to calculate total XP required to REACH a level
    private func cumulativeXP(forLevel level: Int) -> Int {
        var total = 0
        for i in 1..<level {
            total += i * 100
        }
        return total
    }
    
    var currentLevel: Int {
        user?.stats?.safeLevel ?? 1
    }
    
    var totalXP: Int {
        user?.stats?.safeXP ?? 0
    }
    
    // Returns XP earned WITHIN the current level (for progress bar)
    var currentXP: Int {
        let total = totalXP
        let startOfLevel = cumulativeXP(forLevel: currentLevel)
        return max(0, total - startOfLevel)
    }
    
    // Returns XP needed to complete CURRENT level
    var nextLevelXP: Int {
        // XP required for next level: level * 100
        currentLevel * 100
    }
    
    var xpProgress: Double {
        guard nextLevelXP > 0 else { return 0 }
        return Double(currentXP) / Double(nextLevelXP)
    }
    
    var totalGamesPlayed: Int {
        user?.stats?.totalGamesPlayed ?? 0
    }
    
    var totalHoursPlayed: Int {
        user?.stats?.totalHoursPlayed ?? 0
    }
    
    var averageRating: Double {
        user?.stats?.averageRating ?? 0.0
    }
    
    var recentActivities: [RecentActivity] {
        user?.recentActivity ?? []
    }
    
    var achievements: [String] {
        user?.achievements ?? []
    }
    
    var hasAchievements: Bool {
        !achievements.isEmpty
    }
    
    var currentStreak: Int {
        user?.currentStreak ?? 0
    }
    
    var longestStreak: Int {
        user?.longestStreak ?? 0
    }
    
    var streakMultiplier: Double {
        let streak = currentStreak
        if streak >= 30 { return 2.5 }
        if streak >= 14 { return 2.0 }
        if streak >= 7 { return 1.5 }
        if streak >= 3 { return 1.2 }
        return 1.0
    }
    
    var totalMissionsCompleted: Int {
        user?.totalMissionsCompleted ?? 0
    }
    
    var totalReviewsWritten: Int {
        user?.totalReviewsWritten ?? 0
    }
    
    var totalTeammatesMatched: Int {
        user?.totalTeammatesMatched ?? 0
    }
}
