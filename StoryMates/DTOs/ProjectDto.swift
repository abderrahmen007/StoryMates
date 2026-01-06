import Foundation

struct ProjectDto: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let createdAt: Int64
    let updatedAt: Int64
    let isFork: Bool
    let originalProjectId: String?
    let originalAuthorName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, createdAt, updatedAt, isFork, originalProjectId, originalAuthorName
    }
    
    init(id: String, title: String, description: String, createdAt: Int64, updatedAt: Int64, isFork: Bool = false, originalProjectId: String? = nil, originalAuthorName: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFork = isFork
        self.originalProjectId = originalProjectId
        self.originalAuthorName = originalAuthorName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        isFork = (try? container.decode(Bool.self, forKey: .isFork)) ?? false
        originalProjectId = try? container.decode(String.self, forKey: .originalProjectId)
        originalAuthorName = try? container.decode(String.self, forKey: .originalAuthorName)
        
        // Handle optional/missing timestamps by providing defaults
        createdAt = (try? container.decode(Int64.self, forKey: .createdAt)) ?? Int64(Date().timeIntervalSince1970 * 1000)
        updatedAt = (try? container.decode(Int64.self, forKey: .updatedAt)) ?? Int64(Date().timeIntervalSince1970 * 1000)
    }
}
