import Foundation
import SwiftUI
import Combine

@MainActor
class MissionChecklistViewModel: ObservableObject {
    @Published var missions: [Mission] = []
    @Published var progress: MissionProgress?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager()
    private let gameId: Int
    private let gameName: String
    
    init(gameId: Int, gameName: String) {
        self.gameId = gameId
        self.gameName = gameName
    }
    
    func loadMissions() async {
        print("🚀 loadMissions called for game: \(gameName) (ID: \(gameId))")
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch missions from backend
            print("⏳ Calling networkManager.fetchMissions...")
            let gameMissions = try await networkManager.fetchMissions(gameId: gameId, gameName: gameName)
            print("✅ Fetched \(gameMissions.missions.count) missions")
            missions = gameMissions.missions
            
            // Fetch progress
            if let userId = AuthManager.shared.userId {
                print("👤 Fetching progress for user: \(userId)")
                do {
                    progress = try await networkManager.getMissionProgress(userId: userId, gameId: gameId)
                    print("✅ Progress fetched: \(progress?.completedMissions.count ?? 0) completed")
                    updateMissionsWithProgress()
                } catch {
                    print("⚠️ Failed to fetch progress (using empty): \(error)")
                    // If no progress exists yet, initialize empty
                    progress = MissionProgress(
                        completedMissions: [],
                        totalMissions: missions.count,
                        lastUpdated: Date()
                    )
                }
            } else {
                print("⚠️ No userId found, skipping progress fetch")
            }
            
            isLoading = false
        } catch {
            print("❌ loadMissions failed: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func toggleMission(_ mission: Mission) {
        print("🔘 [ToggleMission] Tapped mission #\(mission.number): \(mission.title)")
        print("🔘 [ToggleMission] Current completion status: \(mission.isCompleted)")
        
        guard let userId = AuthManager.shared.userId else {
            print("❌ [ToggleMission] No userId found")
            return
        }
        
        print("✅ [ToggleMission] UserId: \(userId)")
        
        Task {
            do {
                print("📤 [ToggleMission] Sending toggle request to backend...")
                let newProgress = try await networkManager.toggleMission(
                    userId: userId,
                    gameId: gameId,
                    missionNumber: mission.number,
                    totalMissions: missions.count
                )
                
                print("✅ [ToggleMission] Received new progress: \(newProgress.completedMissions.count)/\(newProgress.totalMissions)")
                print("✅ [ToggleMission] Completed missions: \(newProgress.completedMissions)")
                
                progress = newProgress
                updateMissionsWithProgress()
                
                print("✅ [ToggleMission] UI updated")
            } catch {
                print("❌ [ToggleMission] Error: \(error.localizedDescription)")
                errorMessage = "Failed to update mission: \(error.localizedDescription)"
            }
        }
    }
    
    private func updateMissionsWithProgress() {
        guard let progress = progress else {
            print("⚠️ [UpdateMissions] No progress data available")
            return
        }
        
        print("🔄 [UpdateMissions] Updating \(missions.count) missions with progress")
        print("🔄 [UpdateMissions] Completed missions from backend: \(progress.completedMissions)")
        
        // Create a new array to trigger SwiftUI's change detection
        var updatedMissions: [Mission] = []
        
        for mission in missions {
            var updatedMission = mission
            let wasCompleted = mission.isCompleted
            let shouldBeCompleted = progress.completedMissions.contains(mission.number)
            
            updatedMission.isCompleted = shouldBeCompleted
            updatedMissions.append(updatedMission)
            
            if wasCompleted != shouldBeCompleted {
                print("🔄 [UpdateMissions] Mission #\(mission.number): \(wasCompleted ? "completed" : "incomplete") → \(shouldBeCompleted ? "completed" : "incomplete")")
            }
        }
        
        // Replace the entire array to trigger @Published update
        missions = updatedMissions
        
        print("✅ [UpdateMissions] Update complete. Total completed: \(missions.filter { $0.isCompleted }.count)")
    }
}
