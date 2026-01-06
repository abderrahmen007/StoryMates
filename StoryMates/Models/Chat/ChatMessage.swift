import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: String?
    let senderId: String
    let senderName: String
    let content: String
    let roomId: String
    let createdAt: String?
    let audioUrl: String?
    let transcription: String?
    let duration: String?
    var reactions: [Reaction]?
    let replyTo: ReplyInfo?
    let type: String? // "text", "audio", "image"
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case senderId, senderName, sender
        case content
        case roomId, conversationId
        case createdAt, audioUrl, transcription, duration, reactions, replyTo, type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        transcription = try container.decodeIfPresent(String.self, forKey: .transcription)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        reactions = try container.decodeIfPresent([Reaction].self, forKey: .reactions)
        replyTo = try container.decodeIfPresent(ReplyInfo.self, forKey: .replyTo)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // 1. Decode Room ID / Conversation ID
        if let r = try? container.decode(String.self, forKey: .roomId) {
            roomId = r
        } else if let c = try? container.decode(String.self, forKey: .conversationId) {
            roomId = c
        } else {
            roomId = "unknown"
        }
        
        // 2. Decode Sender details
        if let sObj = try? container.decode(User.self, forKey: .sender) {
            // Populated sender object (common in DMs)
            senderId = sObj.id
            senderName = sObj.name ?? "User"
        } else if let sId = try? container.decode(String.self, forKey: .sender) {
            // Sender as ID only
            senderId = sId
            senderName = "User"
        } else {
            // Traditional senderId/senderName fields (common in Rooms)
            senderId = (try? container.decode(String.self, forKey: .senderId)) ?? "unknown"
            senderName = (try? container.decode(String.self, forKey: .senderName)) ?? "User"
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(content, forKey: .content)
        try container.encode(roomId, forKey: .roomId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try container.encodeIfPresent(transcription, forKey: .transcription)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(reactions, forKey: .reactions)
        try container.encodeIfPresent(replyTo, forKey: .replyTo)
        try container.encodeIfPresent(type, forKey: .type)
    }
}

extension ChatMessage: Equatable, Hashable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
