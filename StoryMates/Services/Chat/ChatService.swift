import Foundation

class ChatService {
    private let baseURL: String
    
    init(baseURL: String = "http://localhost:3001") {
        self.baseURL = baseURL
    }
    
    // MARK: - Rooms
    
    func fetchRooms() async throws -> [ChatRoom] {
        guard let url = URL(string: "\(baseURL)/chat/rooms") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([ChatRoom].self, from: data)
    }
    
    func createRoom(name: String, description: String) async throws -> ChatRoom {
        guard let url = URL(string: "\(baseURL)/chat/rooms") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "name": name,
            "description": description
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(ChatRoom.self, from: data)
    }
    
    // MARK: - Messages
    
    func fetchMessages(roomId: String) async throws -> [ChatMessage] {
        guard let url = URL(string: "\(baseURL)/chat/rooms/\(roomId)/messages") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([ChatMessage].self, from: data)
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
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(AudioUploadResponse.self, from: data)
    }
}
