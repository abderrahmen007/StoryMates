import Foundation

struct AppNotification: Codable, Identifiable {
    let id: String
    let type: String // "LIKE" or "COMMENT"
    let fromUser: NotificationUser?
    let toUser: String
    let postId: NotificationPost?
    let isRead: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case fromUser
        case toUser
        case postId
        case isRead = "read"
        case createdAt
    }
}
