// MARK: - Story Project ViewModel

import Foundation
import Combine

class StoryProjectViewModel: ObservableObject {
    @Published var projects: [ProjectDto] = []
    @Published var isLoading = false
    @Published var currentProject: ProjectDto?
    @Published var publishState: PublishState = .idle
    
    // References state
    @Published var references: [Reference] = []
    @Published var projectArtStyle: ProjectArtStyle?
    @Published var referencesLoading = false
    
    private let repository = StoryProjectRepository()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadProjects()
    }
    
    // MARK: - Load Projects
    func loadProjects() {
        isLoading = true
        Task {
            do {
                let fetchedProjects = try await repository.getAllProjects()
                await MainActor.run {
                    self.projects = fetchedProjects
                    self.isLoading = false
                }
            } catch {
                print("Error loading projects: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Create New Project
    func createNewProject(title: String, description: String = "", onSuccess: @escaping (String) -> Void) {
        Task {
            do {
                let dto = CreateProjectDto(title: title, description: description)
                let project = try await repository.createProject(dto: dto)
                loadProjects()
                await MainActor.run {
                    onSuccess(project.id)
                }
            } catch {
                print("Error creating project: \(error)")
            }
        }
    }
    
    // MARK: - Delete Project
    func deleteProject(projectId: String) {
        Task {
            do {
                try await repository.deleteProject(projectId: projectId)
                loadProjects()
            } catch {
                print("Error deleting project: \(error)")
            }
        }
    }
    
        // MARK: - Load Flowchart
    func loadFlowchart(projectId: String, callback: @escaping (FlowchartState?) -> Void) {
         print("🔄 loadFlowchart called for project: \(projectId)")
         
         Task {
             do {
                 if let flowchartDto = try await repository.getFlowchart(projectId: projectId) {
                     let state = flowchartDto.toFlowchartState()
                     await MainActor.run {
                         print("✅ Flowchart loaded successfully")
                         callback(state)
                     }
                 } else {
                     await MainActor.run {
                         print("⚠️ No flowchart found, creating new")
                         callback(nil)
                     }
                 }
             } catch {
                 print("❌ Error loading flowchart: \(error)")
                 await MainActor.run {
                     callback(nil)
                 }
             }
         }
     }
    
    // MARK: - Save Flowchart
    func saveFlowchart(projectId: String, state: FlowchartState) {
        Task {
            do {
                let nodeDtos = state.nodes.map { $0.toDto() }
                let flowchartDto = FlowchartDto(
                    projectId: projectId,
                    nodes: nodeDtos,
                    updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
                )
                try await repository.saveFlowchart(flowchart: flowchartDto)
                loadProjects()
            } catch {
                print("Error saving flowchart: \(error)")
            }
        }
    }
    
    // MARK: - Set Current Project
    func setCurrentProject(projectId: String) {
        currentProject = projects.first { $0.id == projectId }
    }
    
    // MARK: - Publish Project
    func publishProject(projectId: String, onSuccess: @escaping () -> Void = {}) {
        publishState = .loading
        Task {
            do {
                _ = try await repository.publishProject(projectId: projectId)
                await MainActor.run {
                    self.publishState = .success
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.publishState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Reset Publish State
    func resetPublishState() {
        publishState = .idle
    }
    
    // MARK: - References
    
    func loadReferences(projectId: String) {
        referencesLoading = true
        // Clear old data immediately to prevent cross-project pollution
        self.references = []
        self.projectArtStyle = nil
        
        Task {
            do {
                if let dto = try await repository.getReferences(projectId: projectId) {
                    let refs = dto.references.map { $0.toReference() }
                    let art = dto.toProjectArtStyle()
                    await MainActor.run {
                        self.references = refs
                        self.projectArtStyle = art
                        self.referencesLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.references = []
                        self.projectArtStyle = nil
                        self.referencesLoading = false
                    }
                }
            } catch {
                print("Error loading references: \(error)")
                await MainActor.run {
                    self.references = []
                    self.projectArtStyle = nil
                    self.referencesLoading = false
                }
            }
        }
    }
    
    func updateArtStyle(projectId: String, artStyle: ArtStyle, dimension: ArtDimension) {
        Task {
            do {
                let dto = UpdateArtStyleDto(artStyle: artStyle.rawValue, artDimension: dimension.rawValue)
                try await repository.updateArtStyle(projectId: projectId, dto: dto)
                await MainActor.run {
                    self.projectArtStyle = ProjectArtStyle(artStyle: artStyle, dimension: dimension)
                }
            } catch {
                print("Error updating art style: \(error)")
            }
        }
    }
    
    func addReference(projectId: String, reference: Reference, completion: @escaping () -> Void = {}) {
        Task {
            do {
                let dto = AddReferenceDto(
                    type: reference.type.rawValue,
                    name: reference.name,
                    lore: reference.lore,
                    design: reference.design
                )
                let addedDto = try await repository.addReference(projectId: projectId, dto: dto)
                await MainActor.run {
                    self.references.append(addedDto.toReference())
                    completion()
                }
            } catch {
                print("Error adding reference: \(error)")
            }
        }
    }
    
    func updateReference(projectId: String, reference: Reference) {
        Task {
            do {
                try await repository.updateReference(projectId: projectId, referenceId: reference.id, dto: reference.toDto())
                await MainActor.run {
                    if let index = self.references.firstIndex(where: { $0.id == reference.id }) {
                        self.references[index] = reference
                    }
                }
            } catch {
                print("Error updating reference: \(error)")
            }
        }
    }
    
    func deleteReference(projectId: String, referenceId: String) {
        Task {
            do {
                try await repository.deleteReference(projectId: projectId, referenceId: referenceId)
                await MainActor.run {
                    self.references.removeAll { $0.id == referenceId }
                }
            } catch {
                print("Error deleting reference: \(error)")
            }
        }
    }
    
    func generateReferenceAssets(projectId: String, referenceId: String, completion: @escaping (String?, String?) -> Void, onError: @escaping (String) -> Void) {
        Task {
            do {
                let assets = try await repository.generateReferenceAssets(projectId: projectId, referenceId: referenceId)
                await MainActor.run {
                    // Update the reference in the list with new data
                    if let index = self.references.firstIndex(where: { $0.id == referenceId }) {
                        let old = self.references[index]
                        let updated = Reference(
                            id: old.id,
                            type: old.type,
                            name: old.name,
                            lore: old.lore,
                            design: old.design,
                            imageData: assets.imageData ?? old.imageData,
                            modelData: assets.modelData ?? old.modelData,
                            createdAt: old.createdAt,
                            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
                        )
                        self.references[index] = updated
                    }
                    completion(assets.imageData, assets.modelData)
                }
            } catch {
                print("Error generating assets: \(error)")
                await MainActor.run {
                    onError(error.localizedDescription)
                }
            }
        }
    }
}
