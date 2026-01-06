import Foundation

struct AIRecommendation: Codable, Identifiable {
    var id: Int { game.id }
    let game: Game
    let reason: String
    let score: Double
    let factors: [String]?
}
