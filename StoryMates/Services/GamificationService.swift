//
//  GamificationService.swift
//  StoryMates
//
//  Created by Claude on 12/15/24.
//

import Foundation

/// Response from streak/login endpoint
struct StreakResponse: Codable {
    let streak: Int
    let xpAwarded: Int
    let isNewDay: Bool
}

/// Response from XP award
struct XPResult: Codable {
    let xpAwarded: Int
    let newXP: Int
    let newLevel: Int
    let leveledUp: Bool
    let multiplier: Double
}

/// Gamification stats response
struct GamificationStats: Codable {
    let level: Int
    let xp: Int
    let xpToNextLevel: Int
    let currentStreak: Int
    let longestStreak: Int
    let streakMultiplier: Double
    let achievements: [String]
    let totalMissionsCompleted: Int
    let totalReviewsWritten: Int
    let totalTeammatesMatched: Int
}

/// Mission toggle response with XP info
struct MissionToggleResponse: Codable {
    let completedMissions: [Int]
    let totalMissions: Int
    let lastUpdated: String
    let xpResult: XPResult?
    let newAchievements: [String]
}

class GamificationService {
    static let shared = GamificationService()
    private let baseURL: String
    
    private init() {
        self.baseURL = "http://localhost:3001"
    }
    
    /// Record login and update streak
    func recordLogin(userId: String) async throws -> StreakResponse {
        guard let url = URL(string: "\(baseURL)/gamification/login/\(userId)") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(StreakResponse.self, from: data)
    }
    
    /// Get user's gamification stats
    func getStats(userId: String) async throws -> GamificationStats {
        guard let url = URL(string: "\(baseURL)/gamification/stats/\(userId)") else {
            throw NetworkError.badURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.badServerResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(GamificationStats.self, from: data)
    }
    
    /// Get streak info
    func getStreak(userId: String) async throws -> (currentStreak: Int, longestStreak: Int, multiplier: Double) {
        let stats = try await getStats(userId: userId)
        return (stats.currentStreak, stats.longestStreak, stats.streakMultiplier)
    }
    
    /// Get achievements
    func getAchievements(userId: String) async throws -> [String] {
        let stats = try await getStats(userId: userId)
        return stats.achievements
    }
}
