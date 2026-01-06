import Foundation

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let age: Int?
    let role: String?
    var gamerTags: GamerTags?
    var playStyles: [String]?
    var availability: String?
    var languages: [String]?
    var favoriteGame: FavoriteGame?
    var stats: UserStats?
    var recentActivity: [RecentActivity]?
    var achievements: [String]?
    var bio: String?
    var matchScore: Int?
    var matchTags: [String]?
    
    // Gamification fields
    var currentStreak: Int?
    var longestStreak: Int?
    var lastLoginDate: String?
    var totalMissionsCompleted: Int?
    var totalReviewsWritten: Int?
    var totalTeammatesMatched: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, age, role, gamerTags, playStyles, availability, languages, favoriteGame, stats, recentActivity, achievements, bio, matchScore, matchTags
        case currentStreak, longestStreak, lastLoginDate, totalMissionsCompleted, totalReviewsWritten, totalTeammatesMatched
    }
}

struct UserStats: Codable {
    let level: Int?
    let xp: Int?
    let totalGamesPlayed: Int?
    let totalHoursPlayed: Int?
    let averageRating: Double?
    
    // Provide sensible defaults
    var safeLevel: Int { level ?? 1 }
    var safeXP: Int { xp ?? 0 }
}

struct RecentActivity: Codable, Identifiable {
    var id: String { "\(gameId)-\(timestamp.timeIntervalSince1970)" }
    let type: String
    let gameId: Int
    let gameName: String
    let gameCover: String
    let timestamp: Date
    let details: String?
}

struct FavoriteGame: Codable {
    let gameId: Int
    let name: String
    let coverUrl: String
}

struct GamerTags: Codable {
    var psn: String?
    var xbox: String?
    var steam: String?
    var discord: String?
    var nintendo: String?
}
