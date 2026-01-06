import Foundation

struct AudioUploadResponse: Codable {
    let audioUrl: String
    let transcription: String
}

class DirectMessageService {
    private let baseURL: String
    
    init(baseURL: String = "http://localhost:3001") {
        self.baseURL = baseURL
    }
    
    // MARK: - Conversations
    
    /// Fetch all conversations for a user
    func fetchConversations(userId: String) async throws -> [DirectConversation] {
        guard let url = URL(string: "\(baseURL)/direct-messages/conversations/\(userId)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([DirectConversation].self, from: data)
    }
    
    /// Get or create a conversation with another user
    func getOrCreateConversation(userId: String, otherUserId: String) async throws -> DirectConversation {
        guard let url = URL(string: "\(baseURL)/direct-messages/start") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "user1Id": userId,
            "user2Id": otherUserId
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.badServerResponse
        }
        
        // Debug logging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Received conversation JSON: \(jsonString)")
        }
        
        do {
            return try JSONDecoder().decode(DirectConversation.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }
    
    // MARK: - Messages
    
    /// Fetch messages for a conversation
    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        guard let url = URL(string: "\(baseURL)/direct-messages/\(conversationId)/messages") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([ChatMessage].self, from: data)
    }
    
    /// Mark messages as read
    func markAsRead(conversationId: String, userId: String) async throws {
        // NOTE: Backend supports per-message read status via /direct-messages/messages/:messageId/read
        // Implementing per-conversation read status requires a new backend endpoint or looping through messages.
        // For now, this is a no-op to avoid breaking the UI that calls it.
        // TODO: Implement proper read status sync.
        print("⚠️ Mark as read not implemented for conversation scope in iOS client yet.")
    }
    
    // MARK: - User Search
    
    /// Search for users to start a conversation
    func searchUsers(query: String) async throws -> [Participant] {
        // Backend: GET /user (returns all users)
        // iOS: Logic to fetch all and filter
        guard let url = URL(string: "\(baseURL)/user") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let allUsers = try JSONDecoder().decode([User].self, from: data)
        
        // Filter locally
        let filtered = allUsers.filter { user in
            (user.name?.localizedCaseInsensitiveContains(query) ?? false) || 
            (user.email?.localizedCaseInsensitiveContains(query) ?? false)
        }
        
        // Map to Participant
        return filtered.map { user in
            Participant(
                userId: user.id,
                userName: user.name ?? "User",
                avatar: nil,
                isOnline: false,
                lastSeen: nil
            )
        }
    }
    
    // MARK: - Audio Upload
    
    func uploadAudio(fileURL: URL) async throws -> AudioUploadResponse {
        guard let url = URL(string: "\(baseURL)/chat/upload-audio") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let audioData = try Data(contentsOf: fileURL)
        var body = Data()
        
        // Add file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(AudioUploadResponse.self, from: data)
    }
}
