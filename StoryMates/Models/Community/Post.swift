import Foundation

struct Post: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var content: String
    var photo: String?
    var author: User?
    var comments: [Comment]
    var likes: [String]

    enum CodingKeys: String, CodingKey {
        case _id
        case id
        case title, content, photo, author, comments, likes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // accepte _id ou id
        if let value = try? c.decode(String.self, forKey: ._id) {
            id = value
        } else if let value = try? c.decode(String.self, forKey: .id) {
            id = value
        } else {
            throw DecodingError.keyNotFound(CodingKeys._id,
            .init(codingPath: decoder.codingPath, debugDescription: "Missing _id or id"))
        }

        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        photo = try? c.decode(String.self, forKey: .photo)
        author = try? c.decode(User.self, forKey: .author)
        comments = (try? c.decode([Comment].self, forKey: .comments)) ?? []
        
        // Handle likes: could be Int (legacy) or [String]/[User] (backend)
        if let likesArray = try? c.decode([String].self, forKey: .likes) {
            likes = likesArray
        } else if let likesObjects = try? c.decode([User].self, forKey: .likes) {
            likes = likesObjects.map { $0.id ?? "" }.filter { !$0.isEmpty }
        } else if let likesCount = try? c.decode(Int.self, forKey: .likes) {
            // If it's an Int, we can't reconstruct IDs, so we just use empty strings or a dummy ID to match count
            likes = Array(repeating: "unknown", count: likesCount)
        } else {
             likes = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: ._id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(comments, forKey: .comments)
        try container.encode(likes, forKey: .likes)
    }
}
