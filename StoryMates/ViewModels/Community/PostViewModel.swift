import Foundation
import Combine


@MainActor
final class PostViewModel: ObservableObject {

    
    @Published private(set) var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isCreatingPost = false
    @Published var editingPost: Post?

    private let api: CommunityAPIType
    private let socketManager = SocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Get current user ID from AuthManager
    private var currentUserId: String {
        AuthManager.shared.userId ?? "unknown"
    }

    init(api: CommunityAPIType = CommunityAPI()) {
        self.api = api
        setupNotificationListener()
    }
    
    // MARK: - Real-time Updates
    
    private func setupNotificationListener() {
        // Subscribe to notification publisher for real-time updates
        socketManager.notificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                // Refresh posts when we receive a LIKE or COMMENT notification
                if notification.type == "LIKE" || notification.type == "COMMENT" {
                    print("🔔 Received \(notification.type) notification, refreshing posts...")
                    Task {
                        await self.loadPosts()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadPosts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            posts = try await api.fetchPosts()
        } catch {
            handleError(error)
        }
    }

    func like(post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].likes.append(currentUserId) // Optimistic update with actual userId
        
        Task {
            do {
                let updated = try await api.likePost(id: post.id, userId: currentUserId)
                await MainActor.run { [weak self] in
                    self?.replace(with: updated)
                }
            } catch {
                await MainActor.run { [weak self] in
                    if let rollbackIndex = self?.posts.firstIndex(where: { $0.id == post.id }) {
                        self?.posts[rollbackIndex].likes.removeAll(where: { $0 == self?.currentUserId })
                    }
                    self?.handleError(error)
                }
            }
        }
    }

    func dislike(post: Post) {
        Task {
            do {
                let updated = try await api.dislikePost(id: post.id, userId: currentUserId)
                await MainActor.run { [weak self] in
                    self?.replace(with: updated)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleError(error)
                }
            }
        }
    }

    func react(to post: Post, emoji: String) {
        Task {
            do {
                let updated = try await api.reactToPost(id: post.id, emoji: emoji, userId: currentUserId)
                await MainActor.run { [weak self] in
                    self?.replace(with: updated)
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleError(error)
                }
            }
        }
    }

    func addComment(to post: Post, content: String) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        let placeholder = Comment(
            id: UUID().uuidString,
            content: content,
            author: nil,
            post: post.id,
            likes: 0
        )

        posts[index].comments.append(placeholder)

        Task {
            do {
                _ = try await api.addComment(postId: post.id, content: content, userId: currentUserId)
                let refreshed = try await api.fetchPosts()
                await MainActor.run { [weak self] in
                    self?.posts = refreshed
                }
            } catch {
                await MainActor.run { [weak self] in
                    if let rollbackIndex = self?.posts.firstIndex(where: { $0.id == post.id }) {
                        self?.posts[rollbackIndex].comments.removeAll { $0.id == placeholder.id }
                    }
                    self?.handleError(error)
                }
            }
        }
    }

    func createPost(title: String, content: String, photo: String? = nil, onComplete: (() -> Void)? = nil) {
        Task {
            do {
                let created = try await api.createPost(title: title, content: content, photo: photo, userId: currentUserId)
                await MainActor.run { [weak self] in
                    self?.posts.append(created)
                    onComplete?()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleError(error)
                }
            }
        }
    }

    func updatePost(id: String, title: String, content: String, photo: String? = nil, onComplete: (() -> Void)? = nil) {
        Task {
            do {
                let updated = try await api.updatePost(id: id, title: title, content: content, photo: photo)
                await MainActor.run { [weak self] in
                    self?.replace(with: updated)
                    onComplete?()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleError(error)
                }
            }
        }
    }

    func delete(post: Post, onComplete: (() -> Void)? = nil) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let removed = posts.remove(at: index)

        Task {
            do {
                try await api.deletePost(id: removed.id)
                await MainActor.run {
                    onComplete?()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.posts.insert(removed, at: index)
                    self?.handleError(error)
                }
            }
        }
    }

    func refresh() {
        Task { await loadPosts() }
    }

    // MARK: - Helpers

    private func replace(with post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        var updatedPost = post
        
        // Preserve comments if the server returned an empty list (likely not populated)
        // and we already have comments locally.
        if updatedPost.comments.isEmpty && !posts[index].comments.isEmpty {
            updatedPost.comments = posts[index].comments
        }
        
        // Preserve author if missing
        if updatedPost.author == nil && posts[index].author != nil {
            updatedPost.author = posts[index].author
        }
        
        posts[index] = updatedPost
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

