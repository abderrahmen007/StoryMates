//
//  NetworkManager.swift
//  StoryMates
//
//  Created by mac on 11/19/25.
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case badURL
    case badServerResponse
    case invalidCredentials
    case emailAlreadyInUse
    case invalidToken
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .badServerResponse:
            return "Server error occurred"
        case .invalidCredentials:
            return "Invalid credentials"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .invalidToken:
            return "Invalid or expired reset token"
        case .unknown(let message):
            return message
        }
    }
}

struct SwipeResponse: Codable {
    let match: Bool
    let matchedUser: User?
}

class NetworkManager: ObservableObject {
    // Update this to your local server URL (localhost for iOS Simulator)
    let baseURL = "http://localhost:3001"
    
    func signup(name: String, email: String, password: String) async throws {
        let endpoints = ["/auth/signup"]
        var lastError: Error?
        
        for endpoint in endpoints {
            // Print the full URL for debugging
            let fullURL = "\(baseURL)\(endpoint)"
            print("Attempting to connect to: \(fullURL)")
            
            guard let url = URL(string: fullURL) else {
                print("❌ Failed to create URL from string: \(fullURL)")
                lastError = NetworkError.badURL
                continue
            }
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add timeout interval
            request.timeoutInterval = 10 // 10 seconds timeout
            
            let body: [String: String] = [
                "name": name,
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Debug: Print request details
            print("Signup Request URL: \(endpoint)")
            print("Signup Request Body: \(body)")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                // Debug: Print response for troubleshooting
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Signup Response Status: \(httpResponse.statusCode)")
                    print("Signup Response Body: \(responseString)")
                }
                
                if httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 401 {
                    throw NetworkError.invalidCredentials
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        let errorMessage = errorResponse.message
                        if errorMessage.contains("already in use") {
                            throw NetworkError.emailAlreadyInUse
                        }
                        throw NetworkError.unknown(errorMessage)
                    } else {
                        if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                            throw NetworkError.unknown(errorString)
                        }
                        throw NetworkError.unknown("Server error (Status: \(httpResponse.statusCode))")
                    }
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoints = ["/auth/login"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let body: [String: String] = [
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("Login successful with status code: \(httpResponse.statusCode)")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Login success body:", responseString)
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    do {
                        let authResponse = try decoder.decode(AuthResponse.self, from: data)
                        print("Decoded AuthResponse:", authResponse)
                        return authResponse
                    } catch {
                        print("Login decoding error:", error)
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Login body (on decode error):", responseString)
                        }
                        lastError = NetworkError.badServerResponse
                        continue
                    }
                } else if httpResponse.statusCode == 401 {
                    throw NetworkError.invalidCredentials
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func forgotPassword(email: String) async throws {
        let endpoints = ["/api/auth/forgot-password", "/auth/forgot-password"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "email": email
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func resetPassword(token: String, newPassword: String, email: String) async throws {
        let endpoints = ["/api/auth/reset-password", "/auth/reset-password"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "token": token,
                "newPassword": newPassword,
                "email": email
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 400 {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                       errorResponse.message.contains("Invalid") || errorResponse.message.contains("expired") {
                        throw NetworkError.invalidToken
                    }
                    throw NetworkError.invalidToken
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    // MARK: - Games API
    
    func fetchPopularGames() async throws -> [Game] {
        guard let url = URL(string: "\(baseURL)/games/popular") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    func fetchGamesByGenre(genre: String) async throws -> [Game] {
        guard let encodedGenre = genre.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/games/genre/\(encodedGenre)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    func searchGames(query: String) async throws -> [Game] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/games/search?q=\(encodedQuery)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    
    func getGameDetails(id: Int) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games/\(id)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(Game.self, from: data)
    }
    
    func addToCollection(userId: String, gameId: Int, status: String) async throws {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/collection") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "gameId": gameId,
            "status": status
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.badServerResponse
        }
    }
    
    func getCollection(userId: String) async throws -> [CollectionItem] {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/collection") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CollectionItem].self, from: data)
    }
    
    // MARK: - Missions API
    
    func fetchMissions(gameId: Int, gameName: String) async throws -> GameMissions {
        guard let encodedGameName = gameName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/games/\(gameId)/missions?gameName=\(encodedGameName)") else {
            print("❌ Invalid URL for missions: \(gameName)")
            throw NetworkError.badURL
        }
        
        print("🔍 Fetching missions from: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NetworkError.badServerResponse
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 404 {
                print("❌ No walkthrough found (404)")
                throw NetworkError.unknown("No walkthrough found for this game")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Server error: \(httpResponse.statusCode)")
                throw NetworkError.badServerResponse
            }
            
            let missions = try JSONDecoder().decode(GameMissions.self, from: data)
            print("✅ Successfully decoded \(missions.missions.count) missions")
            return missions
        } catch {
            print("❌ Error fetching missions: \(error)")
            throw error
        }
    }
    
    func getAIRecommendations(userId: String) async throws -> [AIRecommendation] {
        guard let url = URL(string: "\(baseURL)/games/recommendations/\(userId)") else {
            throw NetworkError.badURL
        }
        
        // Add timeout for slower AI responses
        var request = URLRequest(url: url)
        request.timeoutInterval = 15 // 15 seconds timeout for AI generation
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode([AIRecommendation].self, from: data)
    }

    func getMissionProgress(userId: String, gameId: Int) async throws -> MissionProgress {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/collection/\(gameId)/missions/progress") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MissionProgress.self, from: data)
    }
    
    func toggleMission(userId: String, gameId: Int, missionNumber: Int, totalMissions: Int) async throws -> MissionProgress {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/collection/\(gameId)/missions/\(missionNumber)/toggle") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "totalMissions": totalMissions
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MissionProgress.self, from: data)
    }
    
    // MARK: - User API
    
    func fetchUser(id: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/user/\(id)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(User.self, from: data)
    }
    
    func updateUser(id: String, data: [String: Any]) async throws -> User {
        guard let url = URL(string: "\(baseURL)/user/\(id)") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(User.self, from: responseData)
    }
    
    // MARK: - Reviews API
    
    func fetchReviews(gameId: Int) async throws -> [Review] {
        guard let url = URL(string: "\(baseURL)/reviews/game/\(gameId)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return [] // Return empty if no reviews
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Review].self, from: data)
    }
    
    func createReview(userId: String, gameId: Int, rating: Int, text: String) async throws {
        guard let url = URL(string: "\(baseURL)/reviews") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "gameId": gameId,
            "rating": rating,
            "text": text
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    func getGameRating(gameId: Int) async throws -> GameRating {
        guard let url = URL(string: "\(baseURL)/reviews/game/\(gameId)/rating") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return GameRating(average: 0.0, count: 0)
        }
        
        return try JSONDecoder().decode(GameRating.self, from: data)
    }
    
    // MARK: - AI Review Generation
    
    struct AIReviewResponse: Codable {
        let generatedReview: String
        let suggestedTags: [String]
    }
    
    func generateAIReview(gameName: String, rating: Int, quickThoughts: String) async throws -> AIReviewResponse {
        guard let url = URL(string: "\(baseURL)/reviews/ai-generate") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "gameName": gameName,
            "rating": rating,
            "quickThoughts": quickThoughts
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
        
        return try JSONDecoder().decode(AIReviewResponse.self, from: data)
    }
    
    func updateReview(reviewId: String, rating: Int?, text: String?) async throws {
        guard let url = URL(string: "\(baseURL)/reviews/\(reviewId)") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [:]
        if let rating = rating { body["rating"] = rating }
        if let text = text { body["text"] = text }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    func deleteReview(reviewId: String) async throws {
        guard let url = URL(string: "\(baseURL)/reviews/\(reviewId)") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    // MARK: - Recommendations API
    
    func fetchRecommendations(gameId: Int, userId: String) async throws -> [Game] {
        guard let url = URL(string: "\(baseURL)/games/\(gameId)/recommendations?userId=\(userId)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        return try JSONDecoder().decode([Game].self, from: data)
    }
    
    func trackRecommendationClick(userId: String, sourceGameId: Int, clickedGameId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/games/recommendations/track") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "sourceGameId": sourceGameId,
            "clickedGameId": clickedGameId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        // Don't throw error for tracking failures - it's not critical
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            print("Warning: Failed to track recommendation click")
        }
    }
    
    // MARK: - Matches/Teammates API
    
    func getCandidates(userId: String, limit: Int = 10) async throws -> [User] {
        guard let url = URL(string: "\(baseURL)/matches/candidates/\(userId)?limit=\(limit)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([User].self, from: data)
    }
    
    func recordSwipe(swiperId: String, targetId: String, action: String) async throws -> (match: Bool, matchedUser: User?) {
        guard let url = URL(string: "\(baseURL)/matches/swipe") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "swiperId": swiperId,
            "targetId": targetId,
            "action": action
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(SwipeResponse.self, from: data)
        
        return (match: result.match, matchedUser: result.matchedUser)
    }
    
    // MARK: - Nearby/Location API
    
    struct NearbyUser: Codable, Identifiable {
        var id: String { odId }
        let odId: String
        let name: String
        let email: String
        let avatar: String?
        let favoriteGame: FavoriteGame?
        let bio: String?
        let distanceKm: Double?
        let lastActive: Date?
        
        // Computed property for backward compatibility
        var distance: Double? { distanceKm }
        
        enum CodingKeys: String, CodingKey {
            case odId = "_id"
            case name, email, avatar, favoriteGame, bio, distanceKm, lastActive
        }
        
        struct FavoriteGame: Codable {
            let gameId: Int
            let name: String
            let coverUrl: String
        }
    }
    
    func startNearbySearch(userId: String, range: Int) async throws {
        guard let url = URL(string: "\(baseURL)/matches/nearby/start") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "range": range
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    func stopNearbySearch(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/matches/nearby/stop") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    func updateLocation(userId: String, latitude: Double, longitude: Double) async throws {
        guard let url = URL(string: "\(baseURL)/matches/nearby/location") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "latitude": latitude,
            "longitude": longitude
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    func getNearbyUsers(userId: String, range: Int, gameId: Int? = nil) async throws -> [NearbyUser] {
        var urlString = "\(baseURL)/matches/nearby/users?userId=\(userId)&range=\(range)"
        if let gameId = gameId {
            urlString += "&gameId=\(gameId)"
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([NearbyUser].self, from: data)
    }
    
    struct UserProfile: Codable {
        let id: String
        let name: String
        let email: String
        let avatar: String?
        let bio: String?
        let favoriteGame: NearbyUser.FavoriteGame?
        let playStyles: [String]?
        let stats: UserStats?
        
        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name, email, avatar, bio, favoriteGame, playStyles, stats
        }
        
        struct UserStats: Codable {
            let level: Int
            let xp: Int
            let totalGamesPlayed: Int
        }
    }
    
    func searchNearbyUsers(userId: String, latitude: Double, longitude: Double, range: Int, gameId: Int? = nil) async throws -> [NearbyUser] {
        var urlString = "\(baseURL)/matches/nearby?userId=\(userId)&latitude=\(latitude)&longitude=\(longitude)&range=\(range)"
        if let gameId = gameId {
            urlString += "&gameId=\(gameId)"
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([NearbyUser].self, from: data)
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/user/\(userId)/profile") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfile.self, from: data)
    }
    
    func sendInvite(fromUserId: String, toUserId: String, gameId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/matches/invite") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "gameId": gameId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
    }
    
    struct InviteResponse: Codable {
        let match: Bool
        let matchedUser: User?
    }
    
    func respondToInvite(swiperId: String, targetId: String, action: String) async throws -> InviteResponse {
        guard let url = URL(string: "\(baseURL)/matches/respond") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "swiperId": swiperId,
            "targetId": targetId,
            "action": action
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(InviteResponse.self, from: data)
    }
}
