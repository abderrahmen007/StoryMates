import SwiftUI
import Combine

enum SwipeAction {
    case like
    case pass
}

struct SwipeResult {
    let match: Bool
    let matchedUser: User?
}

@MainActor
class TeammateFinderViewModel: ObservableObject {
    @Published var candidates: [User] = []
    @Published var isLoading = false
    @Published var dragOffset: CGSize = .zero
    @Published var errorMessage: String?
    
    private var authManager = AuthManager.shared
    private var networkManager = NetworkManager()
    
    func loadCandidates() async {
        guard let userId = authManager.userId else {
            errorMessage = "Not logged in"
            return
        }
        
        isLoading = true
        do {
            let fetchedCandidates = try await networkManager.getCandidates(userId: userId, limit: 10)
            self.candidates = fetchedCandidates
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading candidates: \(error)")
        }
        isLoading = false
    }
    
    func swipe(on user: User, action: SwipeAction) async -> SwipeResult {
        guard let userId = authManager.userId else {
            return SwipeResult(match: false, matchedUser: nil)
        }
        
        do {
            let result = try await networkManager.recordSwipe(
                swiperId: userId,
                targetId: user.id,
                action: action == .like ? "like" : "pass"
            )
            
            if result.match, let matchedUser = result.matchedUser {
                return SwipeResult(match: true, matchedUser: matchedUser)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error recording swipe: \(error)")
        }
        
        return SwipeResult(match: false, matchedUser: nil)
    }
    
    func removeCurrentCandidate() {
        if !candidates.isEmpty {
            candidates.removeFirst()
        }
        
        // Load more candidates if running low
        if candidates.count < 3 {
            Task {
                await loadCandidates()
            }
        }
    }
}
