import Foundation

struct ReplyInfo: Codable, Equatable {
    let messageId: String
    let content: String
    let senderName: String
}
