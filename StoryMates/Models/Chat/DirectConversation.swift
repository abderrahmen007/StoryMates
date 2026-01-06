import Foundation

struct DirectConversation: Codable, Identifiable, Hashable {
    let id: String
    let participants: [Participant]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    let createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case participants
        case lastMessage
        case unreadCount
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        participants = try container.decode([Participant].self, forKey: .participants)
        lastMessage = try? container.decode(ChatMessage.self, forKey: .lastMessage)
        unreadCount = (try? container.decode(Int.self, forKey: .unreadCount)) ?? 0
        createdAt = (try? container.decode(String.self, forKey: .createdAt)) ?? ""
        updatedAt = (try? container.decode(String.self, forKey: .updatedAt)) ?? ""
    }
    
    // Custom equality and hash removed to allow memberwise comparison
    // This ensures that when lastMessage or unreadCount changes, the view updates
    
    /// Helper to get the other participant in the conversation
    func otherParticipant(currentUserId: String) -> Participant? {
        participants.first { $0.userId != currentUserId }
    }
    
    /// Get display name for the conversation
    func displayName(currentUserId: String) -> String {
        otherParticipant(currentUserId: currentUserId)?.userName ?? "Unknown"
    }
    
    /// Get avatar URL for the conversation
    func displayAvatar(currentUserId: String) -> String? {
        otherParticipant(currentUserId: currentUserId)?.avatar
    }
    
    /// Check if the other participant is online
    func isOtherUserOnline(currentUserId: String) -> Bool {
        otherParticipant(currentUserId: currentUserId)?.isOnline ?? false
    }
}

struct Participant: Codable, Hashable {
    let userId: String
    let userName: String
    let avatar: String?
    let isOnline: Bool
    let lastSeen: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "_id"
        case userName = "name"
        case avatar
        case isOnline
        case lastSeen
    }
    
    init(userId: String, userName: String, avatar: String?, isOnline: Bool, lastSeen: String?) {
        self.userId = userId
        self.userName = userName
        self.avatar = avatar
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        avatar = try? container.decode(String.self, forKey: .avatar)
        isOnline = (try? container.decode(Bool.self, forKey: .isOnline)) ?? false
        lastSeen = try? container.decode(String.self, forKey: .lastSeen)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encodeIfPresent(lastSeen, forKey: .lastSeen)
    }
}
