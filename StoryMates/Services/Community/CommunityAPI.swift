import Foundation

protocol CommunityAPIType {
    func fetchPosts() async throws -> [Post]
    func likePost(id: String, userId: String) async throws -> Post
    func dislikePost(id: String, userId: String) async throws -> Post
    func reactToPost(id: String, emoji: String, userId: String) async throws -> Post
    func reactToComment(id: String, emoji: String, userId: String) async throws -> Comment
    func addComment(postId: String, content: String, userId: String) async throws -> Comment
    func createPost(title: String, content: String, photo: String?, userId: String) async throws -> Post
    func updatePost(id: String, title: String, content: String, photo: String?) async throws -> Post
    func deletePost(id: String) async throws
}

struct CommunityAPI: CommunityAPIType {
    typealias TokenProvider = () -> String?

    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let tokenProvider: TokenProvider?

    init(
        baseURL: URL = URL(string: "http://127.0.0.1:3001")!,
        session: URLSession = .shared,
        tokenProvider: TokenProvider? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchPosts() async throws -> [Post] {
        let request = try makeRequest(path: "/community/posts", method: .get)
        return try await send([Post].self, request: request)
    }

    func likePost(id: String, userId: String) async throws -> Post {
        let body = ["userId": userId]
        let request = try makeRequest(path: "/community/like/\(id)", method: .post, body: body)
        return try await send(Post.self, request: request)
    }

    func dislikePost(id: String, userId: String) async throws -> Post {
        let body = ["userId": userId]
        let request = try makeRequest(path: "/community/dislike/\(id)", method: .post, body: body)
        return try await send(Post.self, request: request)
    }

    func reactToPost(id: String, emoji: String, userId: String) async throws -> Post {
        let body = ["emoji": emoji, "userId": userId]
        let request = try makeRequest(path: "/community/post/react/\(id)", method: .post, body: body)
        return try await send(Post.self, request: request)
    }

    func reactToComment(id: String, emoji: String, userId: String) async throws -> Comment {
        let body = ["emoji": emoji, "userId": userId]
        let request = try makeRequest(path: "/community/comment/react/\(id)", method: .post, body: body)
        return try await send(Comment.self, request: request)
    }

    func addComment(postId: String, content: String, userId: String) async throws -> Comment {
        let body = ["postId": postId, "content": content, "userId": userId]
        let request = try makeRequest(path: "/community/comment", method: .post, body: body)
        return try await send(Comment.self, request: request)
    }

    func createPost(title: String, content: String, photo: String?, userId: String) async throws -> Post {
        var body = ["title": title, "content": content, "userId": userId]
        if let photo = photo {
            body["photo"] = photo
        }
        let request = try makeRequest(path: "/community/post", method: .post, body: body)
        return try await send(Post.self, request: request)
    }

    func updatePost(id: String, title: String, content: String, photo: String?) async throws -> Post {
        var body = ["title": title, "content": content]
        if let photo = photo {
            body["photo"] = photo
        }
        let request = try makeRequest(path: "/community/post/\(id)", method: .patch, body: body)
        return try await send(Post.self, request: request)
    }

    func deletePost(id: String) async throws {
        let request = try makeRequest(path: "/community/post/\(id)", method: .delete)
        _ = try await session.data(for: request)
    }

    // MARK: - Helpers

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        body: [String: String]? = nil
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider?(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        return request
    }

    private func send<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            // Try to decode error message from backend
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw BackendError(message: errorResponse.message)
            }
            // Fallback to string if not JSON
            if let errorMessage = String(data: data, encoding: .utf8), !errorMessage.isEmpty {
                throw BackendError(message: errorMessage)
            }
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(T.self, from: data)
    }
}

struct BackendError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
