//
//  AiConversationRepository.swift
//  StoryMates
//
//  Created by Mac Mini 10 on 23/11/2025.
//

import Foundation

struct EmptyResponse: Codable {}

final class AiConversationRepository {
    static let shared = AiConversationRepository()
    private init() {}
    
    let baseURL = "http://localhost:3001/ai-conversations"
    private func makeRequest<T: Decodable>(_ path: String,
                                           method: String = "GET",
                                           body: Data? = nil,
                                           token: String? = nil) async throws -> T {
        
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token {
            request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.badServerResponse
        }
        
        guard 200...299 ~= http.statusCode else {
            // try to pull server message if available
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.unknown(err.message)
            }
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - end-points (1-to-1 with Android)
    
    func createConversation(dto: CreateConversationDto,
                            token: String) async throws -> Conversation {
        let body = try JSONEncoder().encode(dto)
        return try await makeRequest("/", method: "POST", body: body, token: token)
    }
    
    func getConversations(userId: String,
                          token: String) async throws -> [Conversation] {
        try await makeRequest("?userId=\(userId)", token: token)
    }
    
    func createMessage(conversationId: String,
                       dto: CreateMessageDto,
                       token: String) async throws -> Message {
        var copy = dto
        copy.conversationId = conversationId
        let body = try JSONEncoder().encode(copy)
        return try await makeRequest("/\(conversationId)/messages",
                                     method: "POST",
                                     body: body,
                                     token: token)
    }
    
    func getMessages(conversationId: String,
                     userId: String,
                     token: String) async throws -> [Message] {
        try await makeRequest("/\(conversationId)/messages?userId=\(userId)",
                              token: token)
    }
    
    func editMessage(messageId: String,
                     newText: String,
                     token: String) async throws -> Message {
        let body = try JSONEncoder().encode(["content": newText])
        return try await makeRequest("/messages/\(messageId)",
                                     method: "PUT",
                                     body: body,
                                     token: token)
    }
    
    func deleteMessage(messageId: String,
                       token: String) async throws {
        let _: EmptyResponse = try await makeRequest("/messages/\(messageId)",
                                                     method: "DELETE",
                                                     token: token)
    }
    
    func editConversation(conversationId: String,
                          title: String,
                          token: String) async throws -> Conversation {
        let body = try JSONEncoder().encode(["title": title])
        return try await makeRequest("/\(conversationId)",
                                     method: "PUT",
                                     body: body,
                                     token: token)
    }
    
    func deleteConversation(conversationId: String,
                            token: String) async throws {
        let _: EmptyResponse = try await makeRequest("/\(conversationId)",
                                                     method: "DELETE",
                                                     token: token)
    }
}
