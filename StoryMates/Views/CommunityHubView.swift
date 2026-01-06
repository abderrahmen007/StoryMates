import SwiftUI

/// Community Hub - Regroupe Messages, Posts, et Rooms
struct CommunityHubView: View {
    @State private var selectedSection: CommunitySection = .posts
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Segmented Picker
                    Picker("", selection: $selectedSection) {
                        ForEach(CommunitySection.allCases, id: \.self) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Content
                    TabView(selection: $selectedSection) {
                        DirectMessageListView()
                            .tag(CommunitySection.messages)
                        
                        CommunityPostsView(showCreateSheet: $showCreatePost)
                            .tag(CommunitySection.posts)
                        
                        ChatRoomListView()
                            .tag(CommunitySection.rooms)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // FAB - Toujours visible quand on est sur Posts
                if selectedSection == .posts {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showCreatePost = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: DirectConversation.self) { conversation in
                DirectMessageView(conversation: conversation)
            }
            .navigationDestination(for: String.self) { roomId in
                VoiceRoomView(
                    roomID: roomId,
                    userID: AuthManager.shared.userId ?? "unknown",
                    userName: AuthManager.shared.userName ?? "User",
                    isCallDeclined: .constant(false)
                )
            }
        }
    }
}

// MARK: - Community Section Enum

enum CommunitySection: String, CaseIterable {
    case messages
    case posts
    case rooms
    
    var title: String {
        switch self {
        case .messages: return "Messages"
        case .posts: return "Posts"
        case .rooms: return "Rooms"
        }
    }
}

// MARK: - Community Posts View

struct CommunityPostsView: View {
    @StateObject private var viewModel = PostViewModel()
    @Binding var showCreateSheet: Bool
    @State private var editingPost: Post?
    @State private var postPendingDeletion: Post?

    var body: some View {
        ZStack {
            Image("background_general")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCardView(
                            post: post,
                            onLike: { viewModel.like(post: post) },
                            onAddComment: { text in viewModel.addComment(to: post, content: text) },
                            onEdit: { editingPost = post },
                            onDelete: { postPendingDeletion = post }
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 160)
            }
            .refreshable { await viewModel.loadPosts() }

            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .task {
            await viewModel.loadPosts()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePostView(
                onCancel: { showCreateSheet = false },
                onSave: { title, content, photo in
                    viewModel.createPost(title: title, content: content, photo: photo) {
                        showCreateSheet = false
                    }
                }
            )
        }
        .sheet(item: $editingPost) { post in
            EditPostView(
                post: post,
                onCancel: { editingPost = nil },
                onSave: { title, content, photo in
                    viewModel.updatePost(id: post.id, title: title, content: content, photo: photo) {
                        editingPost = nil
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete this post?",
            isPresented: Binding(
                get: { postPendingDeletion != nil },
                set: { newValue in
                    if !newValue { postPendingDeletion = nil }
                }
            ),
            presenting: postPendingDeletion
        ) { post in
            Button("Delete", role: .destructive) {
                viewModel.delete(post: post) {
                    postPendingDeletion = nil
                }
            }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            ),
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        )
    }
}

#Preview {
    CommunityHubView()
}
