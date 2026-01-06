import Foundation

struct Reaction: Codable, Identifiable, Equatable {
    var id: String { "\(emoji)_\(userId)" }
    let emoji: String
    let userId: String
    let userName: String
}
