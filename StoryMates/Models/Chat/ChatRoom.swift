import Foundation

struct ChatRoom: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case description
    }
}
