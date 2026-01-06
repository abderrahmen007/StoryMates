import Foundation
import Combine

/// Direct Message ViewModel - Simple implementation matching Android
/// No reactions, no replies (backend doesn't support these for DMs)
@MainActor
class DirectMessageViewModel: ObservableObject {
    @Published var conversations: [DirectConversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentConversation: DirectConversation?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String] = []
    @Published var onlineUsers: Set<String> = []
    
    private let dmService: DirectMessageService
    private let socketManager = SocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(dmService: DirectMessageService = DirectMessageService()) {
        self.dmService = dmService
    }
    
    // MARK: - Socket Handlers
    
    private func setupSocketHandlers() {
        print("🔧 Setting up DM socket handlers")
        
        socketManager.onDirectMessage = { [weak self] message in
            guard let self = self else { return }
            print("📨 Received direct message: \(message.content)")
            
            DispatchQueue.main.async {
                if !self.messages.contains(where: { $0.id == message.id }) {
                    self.objectWillChange.send()
                    self.messages.append(message)
                    print("✅ DM added. Total: \(self.messages.count)")
                }
            }
        }

        socketManager.onTypingInConversation = { [weak self] userName in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !self.typingUsers.contains(userName) {
                    self.objectWillChange.send()
                    self.typingUsers.append(userName)
                }
            }
        }

        socketManager.onStopTypingInConversation = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.typingUsers.removeAll()
            }
        }
        
        socketManager.onUserOnlineStatus = { [weak self] userId, isOnline in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if isOnline {
                    self.onlineUsers.insert(userId)
                } else {
                    self.onlineUsers.remove(userId)
                }
                self.objectWillChange.send()
            }
        }
        
        socketManager.onMessageRead = { [weak self] conversationId in
            guard let self = self else { return }
            print("✅ Messages read in: \(conversationId)")
        }
    }
    
    // MARK: - Conversations
    
    func loadConversations(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedConversations = try await dmService.fetchConversations(userId: userId)
            await MainActor.run {
                self.conversations = fetchedConversations
                self.isLoading = false
                
                if !self.socketManager.isConnected {
                    self.socketManager.connectChat()
                }
                self.socketManager.joinUserRoom(userId: userId)
                self.setupSocketHandlers()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func createConversation(userId: String, otherUserId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newConversation = try await dmService.getOrCreateConversation(userId: userId, otherUserId: otherUserId)
            await MainActor.run {
                if !self.conversations.contains(where: { $0.id == newConversation.id }) {
                    self.conversations.insert(newConversation, at: 0)
                }
                self.currentConversation = newConversation
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func selectConversation(_ conversation: DirectConversation) {
        if let previous = currentConversation, previous.id != conversation.id {
            socketManager.leaveConversation(conversationId: previous.id)
        }
        
        currentConversation = conversation
        socketManager.joinConversation(conversationId: conversation.id)
        
        Task { await loadMessages(conversationId: conversation.id) }
    }
    
    // MARK: - Messages
    
    func loadMessages(conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await dmService.fetchMessages(conversationId: conversationId)
            await MainActor.run {
                self.messages = fetchedMessages
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func sendMessage(
        senderId: String,
        senderName: String,
        content: String,
        conversationId: String
    ) {
        socketManager.sendDirectMessage(
            senderId: senderId,
            senderName: senderName,
            content: content,
            conversationId: conversationId
        )
    }
    
    // MARK: - Voice Messages
    
    func sendVoiceMessage(
        audioURL: URL,
        duration: TimeInterval,
        senderId: String,
        senderName: String,
        conversationId: String
    ) async {
        do {
            let uploadResponse = try await dmService.uploadAudio(fileURL: audioURL)
            let durationString = String(format: "%.1f", duration)
            
            socketManager.sendDirectMessage(
                senderId: senderId,
                senderName: senderName,
                content: uploadResponse.transcription.isEmpty ? "Voice message" : uploadResponse.transcription,
                conversationId: conversationId,
                audioUrl: uploadResponse.audioUrl,
                transcription: uploadResponse.transcription,
                duration: durationString
            )
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload voice message: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Typing
    
    func sendTypingIndicator(userName: String) {
        guard let conversationId = currentConversation?.id else { return }
        socketManager.sendTypingInConversation(conversationId: conversationId, userName: userName)
    }
    
    func sendStopTyping() {
        guard let conversationId = currentConversation?.id else { return }
        socketManager.sendStopTypingInConversation(conversationId: conversationId)
    }
    
    // MARK: - Read Status
    
    func markAsRead(conversationId: String, userId: String) {
        Task {
            do {
                try await dmService.markAsRead(conversationId: conversationId, userId: userId)
                socketManager.markMessagesAsRead(conversationId: conversationId, userId: userId)
            } catch {
                print("❌ Failed to mark as read: \(error)")
            }
        }
    }
    
    // MARK: - User Search
    
    func searchUsers(query: String) async -> [Participant] {
        do {
            return try await dmService.searchUsers(query: query)
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return []
        }
    }
    
    // MARK: - Lifecycle
    
    func connect(conversationId: String, userId: String, userName: String) {
        print("🔌 Connecting to DM: \(conversationId)")
        
        setupSocketHandlers()
        
        if !socketManager.isConnected {
            socketManager.connectChat()
        }
        
        socketManager.joinConversation(conversationId: conversationId)
        socketManager.updateOnlineStatus(userId: userId, isOnline: true)
    }
    
    func disconnect(conversationId: String, userId: String) {
        print("👋 Disconnecting from DM: \(conversationId)")
        socketManager.leaveConversation(conversationId: conversationId)
        socketManager.updateOnlineStatus(userId: userId, isOnline: false)
    }
    
    // MARK: - Calls
    
    func startCall(callerId: String, callerName: String, calleeId: String, roomId: String) {
        CallManager.shared.startCall(
            callerId: callerId,
            callerName: callerName,
            calleeId: calleeId,
            calleeName: "User",
            roomId: roomId
        )
    }
    
    func acceptCall(callId: String, callerId: String, calleeId: String) {
        socketManager.acceptCall(callId: callId, callerId: callerId, calleeId: calleeId, calleeName: AuthManager.shared.userName ?? "User")
    }

    func cancelCall(callId: String, callerId: String, calleeId: String) {
        socketManager.cancelCall(callId: callId, callerId: callerId, calleeId: calleeId)
    }

    func endCall(callId: String, userId: String, otherUserId: String) {
        socketManager.endCall(callId: callId, userId: userId, otherUserId: otherUserId)
    }

    func declineCall(callId: String, callerId: String, calleeId: String) {
        socketManager.declineCall(callId: callId, callerId: callerId, calleeId: calleeId, calleeName: AuthManager.shared.userName ?? "User")
    }
}
