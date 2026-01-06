import Foundation

struct ReferenceDto: Codable {
    let id: String
    let type: String
    let name: String
    let lore: String
    let design: String
    let imageData: String?
    let modelData: String?
    let createdAt: Int64
    let updatedAt: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, lore, design, imageData, modelData, createdAt, updatedAt
    }
    
    init(id: String, type: String, name: String, lore: String, design: String, imageData: String?, modelData: String?, createdAt: Int64, updatedAt: Int64) {
        self.id = id
        self.type = type
        self.name = name
        self.lore = lore
        self.design = design
        self.imageData = imageData
        self.modelData = modelData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        lore = try container.decode(String.self, forKey: .lore)
        design = try container.decode(String.self, forKey: .design)
        imageData = try? container.decode(String.self, forKey: .imageData)
        modelData = try? container.decode(String.self, forKey: .modelData)
        
        createdAt = (try? container.decode(Int64.self, forKey: .createdAt)) ?? Int64(Date().timeIntervalSince1970 * 1000)
        updatedAt = (try? container.decode(Int64.self, forKey: .updatedAt)) ?? Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    func toReference() -> Reference {
        Reference(
            id: id,
            type: ReferenceType(rawValue: type) ?? .CHARACTER,
            name: name,
            lore: lore,
            design: design,
            imageData: imageData,
            modelData: modelData,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct ProjectReferencesDto: Codable {
    let projectId: String
    let references: [ReferenceDto]
    let artStyle: String?
    let artDimension: String?
    let updatedAt: Int64?
    
    func toProjectArtStyle() -> ProjectArtStyle? {
        guard let style = artStyle, let dimension = artDimension else {
            return nil
        }
        return ProjectArtStyle(
            artStyle: ArtStyle(rawValue: style) ?? .STANDARD_2D,
            dimension: ArtDimension(rawValue: dimension) ?? .TWO_D
        )
    }
}

struct UpdateArtStyleDto: Codable {
    let artStyle: String
    let artDimension: String
}

struct AddReferenceDto: Codable {
    let type: String
    let name: String
    let lore: String
    let design: String
}

struct GeneratedAssetsDto: Codable {
    let imageData: String?
    let modelData: String?
}

extension Reference {
    func toDto() -> ReferenceDto {
        ReferenceDto(
            id: id,
            type: type.rawValue,
            name: name,
            lore: lore,
            design: design,
            imageData: imageData,
            modelData: modelData,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ProjectArtStyle {
    func toUpdateDto() -> UpdateArtStyleDto {
        UpdateArtStyleDto(
            artStyle: artStyle.rawValue,
            artDimension: dimension.rawValue
        )
    }
}
