import Foundation
import Combine
import OSLog

private struct StoryProjectEmptyResponse: Codable {}

// MARK: - Story Project Repository

class StoryProjectRepository {
    private let baseURL = "\(APIClient.baseURL)/projects"
    private let communityBaseURL = "\(APIClient.baseURL)/community-projects"
    private static let logger = Logger(subsystem: "com.storymate", category: "StoryProjectRepo")
    
    func getAllProjects() async throws -> [ProjectDto] {
        Self.logger.info("📤 GET /projects")
        let result: [ProjectDto] = try await APIClient.shared.request(endpoint: "/projects")
        Self.logger.info("📥 Response: \(result.count) projects")
        return result
    }
    
    func getProject(id: String) async throws -> ProjectDto? {
        do {
            Self.logger.info("📤 GET /projects/\(id)")
            let result: ProjectDto = try await APIClient.shared.request(endpoint: "/projects/\(id)")
            Self.logger.info("📥 Response: Project '\(result.title)'")
            return result
        } catch {
            Self.logger.error("❌ getProject failed: \(error)")
            return nil
        }
    }
    
    func createProject(dto: CreateProjectDto) async throws -> ProjectDto {
        Self.logger.info("📤 POST /projects")
        Self.logger.info("📤 Body: title='\(dto.title)', description='\(dto.description ?? "nil")'")
        
        let result: ProjectDto = try await APIClient.shared.request(
            endpoint: "/projects",
            method: "POST",
            body: dto
        )
        
        Self.logger.info("📥 Response: Created project '\(result.title)' with ID '\(result.id)'")
        return result
    }
    
    func saveProject(project: ProjectDto) async throws {
        Self.logger.info("📤 PUT /projects/\(project.id)")
        Self.logger.info("📤 Body: title='\(project.title)', description='\(project.description ?? "nil")'")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(project.id)",
            method: "PUT",
            body: project
        )
        
        Self.logger.info("📥 Response: Project updated successfully")
    }
    
    func deleteProject(projectId: String) async throws {
        Self.logger.info("📤 DELETE /projects/\(projectId)")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)",
            method: "DELETE"
        )
        
        Self.logger.info("📥 Response: Project deleted successfully")
    }
    
    func getFlowchart(projectId: String) async throws -> FlowchartDto? {
        do {
            Self.logger.info("📤 GET /projects/\(projectId)/flowchart")
            let result: FlowchartDto = try await APIClient.shared.request(endpoint: "/projects/\(projectId)/flowchart")
            Self.logger.info("📥 Response: Flowchart with \(result.nodes.count) nodes")
            return result
        } catch {
            Self.logger.error("❌ getFlowchart failed: \(error)")
            return nil
        }
    }
    
    func saveFlowchart(flowchart: FlowchartDto) async throws {
        Self.logger.info("📤 POST /projects/\(flowchart.projectId)/flowchart")
        Self.logger.info("📤 Body: \(flowchart.nodes.count) nodes")
        
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(flowchart.projectId)/flowchart",
            method: "POST",
            body: flowchart
        )
        
        Self.logger.info("📥 Response: Flowchart saved successfully")
    }
    
    func publishProject(projectId: String) async throws -> CommunityProjectDto {
        Self.logger.info("📤 POST /community-projects/publish")
        Self.logger.info("📤 Body: projectId='\(projectId)'")
        
        let dto = PublishProjectDto(projectId: projectId)
        let result: CommunityProjectDto = try await APIClient.shared.request(
            endpoint: "/community-projects/publish",
            method: "POST",
            body: dto
        )
        
        Self.logger.info("📥 Response: Published project '\(result.title)' with ID '\(result.id)'")
        return result
    }
    
    // MARK: - References
    
    func getReferences(projectId: String) async throws -> ProjectReferencesDto? {
        do {
            Self.logger.info("📤 GET /projects/\(projectId)/references")
            let result: ProjectReferencesDto = try await APIClient.shared.request(endpoint: "/projects/\(projectId)/references")
            Self.logger.info("📥 Response: \(result.references.count) references")
            return result
        } catch {
            Self.logger.error("❌ getReferences failed: \(error)")
            return nil
        }
    }
    
    func addReference(projectId: String, dto: AddReferenceDto) async throws -> ReferenceDto {
        Self.logger.info("📤 POST /projects/\(projectId)/references")
        let result: ReferenceDto = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)/references",
            method: "POST",
            body: dto
        )
        Self.logger.info("📥 Response: Added reference '\(result.name)'")
        return result
    }
    
    func updateReference(projectId: String, referenceId: String, dto: ReferenceDto) async throws {
        Self.logger.info("📤 PUT /projects/\(projectId)/references/\(referenceId)")
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)/references/\(referenceId)",
            method: "PUT",
            body: dto
        )
        Self.logger.info("📥 Response: Updated reference")
    }
    
    func deleteReference(projectId: String, referenceId: String) async throws {
        Self.logger.info("📤 DELETE /projects/\(projectId)/references/\(referenceId)")
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)/references/\(referenceId)",
            method: "DELETE"
        )
        Self.logger.info("📥 Response: Deleted reference")
    }
    
    func updateArtStyle(projectId: String, dto: UpdateArtStyleDto) async throws {
        Self.logger.info("📤 PUT /projects/\(projectId)/art-style")
        let _: StoryProjectEmptyResponse = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)/art-style",
            method: "PUT",
            body: dto
        )
        Self.logger.info("📥 Response: Updated art style")
    }
    
    func generateReferenceAssets(projectId: String, referenceId: String) async throws -> GeneratedAssetsDto {
        Self.logger.info("📤 POST /projects/\(projectId)/references/\(referenceId)/generate-assets")
        let result: GeneratedAssetsDto = try await APIClient.shared.request(
            endpoint: "/projects/\(projectId)/references/\(referenceId)/generate-assets",
            method: "POST"
        )
        Self.logger.info("📥 Response: Generated assets")
        return result
    }
}
