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
    private func log(_ message: String) {
            print("🟦 [Repository] \(message)")
        }

        private func makeRequest<T: Decodable>(_ path: String,
                                               method: String = "GET",
                                               body: Data? = nil,
                                               token: String? = nil) async throws -> T {
            
            guard let url = URL(string: baseURL + path) else {
                log("❌ Bad URL: \(baseURL + path)")
                throw NetworkError.badURL
            }

            log("➡️ Request: \(method) \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let t = token {
                request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
                log("🔑 Token added")
            }

            if let body = body {
                log("📨 Body: \(String(data: body, encoding: .utf8) ?? "Unable to decode body")")
            }

            request.httpBody = body
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(for: request)

            // Log raw response
            log("📥 Raw Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")

            guard let http = response as? HTTPURLResponse else {
                log("❌ Invalid server response")
                throw NetworkError.badServerResponse
            }

            log("📡 Status Code: \(http.statusCode)")

            guard 200...299 ~= http.statusCode else {
                log("❌ Server error \(http.statusCode)")
                if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    log("❌ Error message: \(err.message)")
                    throw NetworkError.unknown(err.message)
                }
                throw NetworkError.badServerResponse
            }

            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                log("✅ Successfully decoded response")
                return decoded
            } catch {
                log("❌ Decoding failed: \(error.localizedDescription)")
                throw error
            }
        }
    
    
    
    func makeRequestRaw(_ path: String, method: String = "GET", token: String? = nil) async throws -> Data {
        
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = method
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return data  // return raw data instead of decoding
    }

        // ENDPOINTS
        func createConversation(dto: CreateConversationDto, token: String) async throws -> Conversation {
            log("📌 createConversation() called")
            let body = try JSONEncoder().encode(dto)
            return try await makeRequest("/", method: "POST", body: body, token: token)
        }

        func getConversations(userId: String, token: String) async throws -> [Conversation] {
            log("📌 getConversations() called for userId=\(userId)")
            return try await makeRequest("?userId=\(userId)", token: token)
        }

        func createMessage(conversationId: String, dto: CreateMessageDto, token: String) async throws -> Message {
            log("📌 createMessage() called for conversation \(conversationId)")
            var copy = dto
            copy.conversationId = conversationId
            let body = try JSONEncoder().encode(copy)
            return try await makeRequest("/\(conversationId)/messages", method: "POST", body: body, token: token)
        }

        func getMessages(conversationId: String, userId: String, token: String) async throws -> [Message] {
            log("📌 getMessages() called for conv \(conversationId)")
            return try await makeRequest("/\(conversationId)/messages?userId=\(userId)", token: token)
        }

        func editMessage(messageId: String, newText: String, token: String) async throws -> Message {
            log("📌 editMessage() called for msg \(messageId)")
            let body = try JSONEncoder().encode(["content": newText])
            return try await makeRequest("/messages/\(messageId)", method: "PUT", body: body, token: token)
        }

    func deleteMessage(conversationId: String, messageId: String, token: String) async throws {
        log("📌 deleteMessage() called for conv \(conversationId), msg \(messageId)")
        
        // Make the request and get raw data for logging
        let responseData: Data = try await makeRequestRaw("/\(conversationId)/messages/\(messageId)", method: "DELETE", token: token)
        
        // Log the response
        if let responseString = String(data: responseData, encoding: .utf8) {
            log("🗑️ deleteMessage() response: \(responseString)")
        } else {
            log("🗑️ deleteMessage() response: <non-UTF8 data>")
        }
    }



        func editConversation(conversationId: String, title: String, token: String) async throws -> Conversation {
            log("📌 editConversationTitle() called for conv \(conversationId)")
            let body = try JSONEncoder().encode(["title": title])
            return try await makeRequest("/\(conversationId)", method: "PUT", body: body, token: token)
        }

    func deleteConversation(conversationId: String, token: String) async throws {
        log("📌 deleteConversation() called for conv \(conversationId)")
        
        // Make the request and capture the raw response
        let responseData: Data = try await makeRequestRaw("/\(conversationId)", method: "DELETE", token: token)
        
        // Attempt to convert to string for logging
        if let responseString = String(data: responseData, encoding: .utf8) {
            log("🗑️ deleteConversation() response: \(responseString)")
        } else {
            log("🗑️ deleteConversation() response: <non-UTF8 data>")
        }
    }

    }
