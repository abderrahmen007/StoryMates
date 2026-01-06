import Foundation

struct NotificationUser: Codable {
    let id: String
    let name: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
    }
}
