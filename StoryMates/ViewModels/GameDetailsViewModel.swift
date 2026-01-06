import SwiftUI
import Combine

@MainActor
class GameDetailsViewModel: ObservableObject {
    @Published var gameDetails: Game?
    @Published var isLoading = true
    @Published var selectedStatus = "want_to_play"
    @Published var showingStatusAlert = false
    @Published var reviews: [Review] = []
    @Published var gameRating: GameRating?
    @Published var showingWriteReview = false
    @Published var recommendations: [Game] = []
    
    // Review edit/delete state
    @Published var showingEditReview = false
    @Published var showingDeleteConfirmation = false
    @Published var reviewToEdit: Review?
    @Published var reviewToDelete: Review?
    @Published var editedRating: Int = 0
    @Published var editedText: String = ""
    
    let gameId: Int
    private var networkManager = NetworkManager()
    
    // Get current user ID for review ownership check
    var currentUserId: String? {
        AuthManager.shared.userId
    }
    
    let statuses = [
        ("want_to_play", "Want to Play"),
        ("playing", "Playing"),
        ("played", "Played")
    ]
    
    init(gameId: Int) {
        self.gameId = gameId
    }
    
    func loadDetails() async {
        do {
            async let detailsTask = networkManager.getGameDetails(id: gameId)
            async let reviewsTask = networkManager.fetchReviews(gameId: gameId)
            async let ratingTask = networkManager.getGameRating(gameId: gameId)
            
            let (details, reviews, rating) = try await (detailsTask, reviewsTask, ratingTask)
            
            self.gameDetails = details
            self.reviews = reviews
            self.gameRating = rating
            self.isLoading = false
            
            // Fetch recommendations after details load
            await fetchRecommendations()
        } catch {
            print("Error loading details: \(error)")
            self.isLoading = false
        }
    }
    
    func fetchRecommendations() async {
        guard let userId = AuthManager.shared.userId else { return }
        
        do {
            let recs = try await networkManager.fetchRecommendations(gameId: gameId, userId: userId)
            self.recommendations = recs
        } catch {
            print("Error fetching recommendations: \(error)")
        }
    }
    
    func refreshReviews() async {
        do {
            async let reviewsTask = networkManager.fetchReviews(gameId: gameId)
            async let ratingTask = networkManager.getGameRating(gameId: gameId)
            
            let (reviews, rating) = try await (reviewsTask, ratingTask)
            
            self.reviews = reviews
            self.gameRating = rating
        } catch {
            print("Error refreshing reviews: \(error)")
        }
    }
    
    func prepareEditReview() {
        guard let review = reviewToEdit else { return }
        editedRating = review.rating
        editedText = review.text
    }
    
    func updateReview() async {
        guard let review = reviewToEdit else { return }
        
        do {
            try await networkManager.updateReview(
                reviewId: review.id,
                rating: editedRating,
                text: editedText
            )
            await refreshReviews()
            showingEditReview = false
            reviewToEdit = nil
        } catch {
            print("Error updating review: \(error)")
        }
    }
    
    func deleteReview() async {
        guard let review = reviewToDelete else { return }
        
        do {
            try await networkManager.deleteReview(reviewId: review.id)
            await refreshReviews()
            showingDeleteConfirmation = false
            reviewToDelete = nil
        } catch {
            print("Error deleting review: \(error)")
        }
    }
    
    func addToCollection() {
        print("🔘 [Collection] Button tapped - addToCollection called")
        
        guard let userId = AuthManager.shared.userId else {
            print("❌ [Collection] No userId found in AuthManager")
            print("❌ [Collection] AuthManager.shared.userId is nil - user not logged in?")
            return
        }
        
        print("✅ [Collection] UserId found: \(userId)")
        print("📦 [Collection] GameId: \(gameId), Status: \(selectedStatus)")
        
        Task {
            do {
                try await networkManager.addToCollection(userId: userId, gameId: gameId, status: selectedStatus)
                self.showingStatusAlert = true
                print("✅ [Collection] Alert should show now")
            } catch {
                print("❌ [Collection] Error adding to collection: \(error)")
            }
        }
    }
}
