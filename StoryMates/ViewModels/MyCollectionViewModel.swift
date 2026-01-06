import SwiftUI
import Combine

@MainActor
class MyCollectionViewModel: ObservableObject {
    @Published var collection: [CollectionItem] = []
    @Published var games: [Int: Game] = [:]
    
    private var networkManager = NetworkManager()
    
    func loadCollection() async {
        guard let userId = AuthManager.shared.userId else { return }
        do {
            let items = try await networkManager.getCollection(userId: userId)
            self.collection = items
            // Load details for games in collection
            for item in items {
                if self.games[item.gameId] == nil {
                    await self.loadGameDetails(id: item.gameId)
                }
            }
        } catch {
            print("Error loading collection: \(error)")
        }
    }
    
    func loadGameDetails(id: Int) async {
        do {
            let game = try await networkManager.getGameDetails(id: id)
            self.games[id] = game
        } catch {
            print("Error loading game details: \(error)")
        }
    }
}
