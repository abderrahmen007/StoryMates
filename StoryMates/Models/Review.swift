import Foundation

struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let gameId: Int
    let rating: Int
    let text: String
    let timestamp: Date
    let likes: Int
    let user: ReviewUser?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, gameId, rating, text, timestamp, likes, user
    }
}

struct ReviewUser: Codable {
    let id: String
    let name: String
    let avatar: String
}

struct GameRating: Codable {
    let average: Doublex
    let count: Int
}
