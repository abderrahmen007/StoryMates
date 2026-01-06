import Foundation

struct Comment: Codable, Identifiable, Hashable {
    let id: String
    let content: String
    let author: User?
    let post: String?
    let likes: Int

    enum CodingKeys: String, CodingKey {
        case _id
        case id
        case content, author, post, likes
    }

    // 👇 Init personnalisé pour JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        if let v = try? c.decode(String.self, forKey: ._id) {
            id = v
        } else if let v = try? c.decode(String.self, forKey: .id) {
            id = v
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys._id,
                .init(codingPath: decoder.codingPath, debugDescription: "Missing id")
            )
        }

        content = (try? c.decode(String.self, forKey: .content)) ?? ""
        author = try? c.decode(User.self, forKey: .author)
        post = try? c.decode(String.self, forKey: .post)
        likes = (try? c.decode(Int.self, forKey: .likes)) ?? 0
    }

    // 👇 Init manuel pour créer un Comment dans SwiftUI (placeholder)
    init(
        id: String,
        content: String,
        author: User?,
        post: String?,
        likes: Int
    ) {
        self.id = id
        self.content = content
        self.author = author
        self.post = post
        self.likes = likes
    }

    // 👇 encode pour respecter Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: ._id)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(post, forKey: .post)
        try container.encode(likes, forKey: .likes)
    }
}
