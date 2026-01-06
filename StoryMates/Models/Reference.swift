import Foundation

enum ReferenceType: String, Codable, CaseIterable {
    case CHARACTER
    case ENVIRONMENT
    
    var icon: String {
        switch self {
        case .CHARACTER: return "👤"
        case .ENVIRONMENT: return "🏢"
        }
    }
}

enum ArtDimension: String, Codable {
    case TWO_D = "TWO_D"
    case THREE_D = "THREE_D"
}

enum ArtStyle: String, Codable, CaseIterable {
    case PIXEL_ART = "PIXEL_ART"
    case STANDARD_2D = "STANDARD_2D"
    case LOW_POLY = "LOW_POLY"
    case REALISTIC = "REALISTIC"
    
    var displayName: String {
        switch self {
        case .PIXEL_ART: return "Pixel Art"
        case .STANDARD_2D: return "Standard 2D"
        case .LOW_POLY: return "Low Poly"
        case .REALISTIC: return "Realistic 3D"
        }
    }
}

struct ProjectArtStyle: Codable {
    var artStyle: ArtStyle
    var dimension: ArtDimension
}

struct Reference: Codable, Identifiable {
    let id: String
    let type: ReferenceType
    let name: String
    let lore: String
    let design: String
    let imageData: String?
    let modelData: String?
    let createdAt: Int64
    let updatedAt: Int64
    
    init(id: String = UUID().uuidString, type: ReferenceType, name: String, lore: String, design: String, imageData: String? = nil, modelData: String? = nil, createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000), updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
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
}
