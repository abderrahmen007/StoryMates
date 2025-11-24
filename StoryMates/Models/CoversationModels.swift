//
//  CoversationModels.swift
//  StoryMates
//
//  Created by Mac Mini 10 on 23/11/2025.
//

import Foundation
// MARK: - AI Conversation DTOs (mirror Android models)
struct Conversation: Codable, Identifiable {
    let id: String
    let title: String
    let userId: String
    let messages: [String]?
    let createdAt: String?
    let updatedAt: String?
    let v: Int?
    
    enum CodingKeys: String, CodingKey {
        case id       = "_id"
        case title, userId, messages, createdAt, updatedAt
        case v        = "__v"
    }
}

struct CreateConversationDto: Codable {
    let title: String
    let userId: String
}

struct Message: Codable, Identifiable {
    let id: String
    let conversationId: String
    let sender: String
    let content: String
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId, sender, content, timestamp
    }
}

struct CreateMessageDto: Codable {
    var conversationId: String = ""
    let userId: String
    let content: String
    var sender: String = "user"
}
