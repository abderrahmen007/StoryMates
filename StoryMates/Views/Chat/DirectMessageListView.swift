import SwiftUI

struct DirectMessageListView: View {
    @StateObject private var viewModel = DirectMessageViewModel()
    @State private var showUserSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [Participant] = []
    @State private var pendingConversation: DirectConversation?
    @State private var selectedConversation: DirectConversation?
    
    private let currentUserId = AuthManager.shared.userId ?? "unknown"
    private let currentUserName = AuthManager.shared.userName ?? "User"
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading conversations...")
                } else if viewModel.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
        }
        .navigationDestination(for: DirectConversation.self) { conversation in
            DirectMessageView(conversation: conversation)
        }
        .navigationDestination(for: String.self) { roomId in
            VoiceRoomView(
                roomID: roomId,
                userID: currentUserId,
                userName: currentUserName,
                isCallDeclined: .constant(false)
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showUserSearch = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showUserSearch, onDismiss: {
            if let conversation = pendingConversation {
                print("🚀 Navigating to pending conversation: \(conversation.id)")
                selectedConversation = conversation
                pendingConversation = nil
            }
        }) {
            userSearchSheet
        }
        .task {
            await viewModel.loadConversations(userId: currentUserId)
        }
        .refreshable {
            await viewModel.loadConversations(userId: currentUserId)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
    
    // MARK: - Conversation List
    
    private var conversationList: some View {
        List(viewModel.conversations) { conversation in
            NavigationLink(value: conversation) {
                DMConversationRow(
                    conversation: conversation,
                    currentUserId: currentUserId
                )
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Start a conversation with someone")
                .font(.subheadline)
                .foregroundColor(.gray)
            Button(action: { showUserSearch = true }) {
                Label("New Message", systemImage: "square.and.pencil")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - User Search Sheet
    
    private var userSearchSheet: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search users...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchQuery) { oldValue, newValue in
                            Task {
                                if !newValue.isEmpty {
                                    searchResults = await viewModel.searchUsers(query: newValue)
                                } else {
                                    searchResults = []
                                }
                            }
                        }
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Search Results
                if searchResults.isEmpty && !searchQuery.isEmpty {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(searchResults, id: \.userId) { user in
                        Button(action: {
                            print("👆 User tapped: \(user.userName)")
                            
                            guard currentUserId != "unknown" else {
                                print("❌ Error: Current user ID is unknown")
                                return
                            }
                            
                            Task {
                                print("🔄 Creating conversation...")
                                await viewModel.createConversation(userId: currentUserId, otherUserId: user.userId)
                                if let newConversation = viewModel.currentConversation {
                                    print("✅ Conversation created: \(newConversation.id)")
                                    pendingConversation = newConversation
                                    showUserSearch = false
                                } else {
                                    print("❌ Failed to create conversation or currentConversation is nil")
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(user.userName.prefix(1)))
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.userName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if user.isOnline {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 8, height: 8)
                                            Text("Online")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showUserSearch = false
                        searchQuery = ""
                        searchResults = []
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Row

struct DMConversationRow: View {
    let conversation: DirectConversation
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(conversation.displayName(currentUserId: currentUserId).prefix(1)))
                            .font(.title2)
                            .foregroundColor(.blue)
                    )
                
                if conversation.isOtherUserOnline(currentUserId: currentUserId) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName(currentUserId: currentUserId))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(formatTime(lastMessage.createdAt ?? ""))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    if let lastMessage = conversation.lastMessage {
                        if lastMessage.audioUrl != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "waveform")
                                    .font(.caption)
                                Text("Voice message")
                            }
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        } else {
                            Text(lastMessage.content)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        DirectMessageListView()
    }
}
