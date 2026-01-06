import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: String
    let name: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case _id
        case id
        case name, email
    }

    // 👇 init JSON
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

        name = try? c.decode(String.self, forKey: .name)
        email = try? c.decode(String.self, forKey: .email)
    }

    // 👇 init manuel (optionnel mais utile si un jour tu veux créer un user placeholder)
    init(id: String, name: String? = nil, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }

    // 👇 encode
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: ._id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(email, forKey: .email)
    }
}
