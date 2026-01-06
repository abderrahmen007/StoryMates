import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [ChatMessage] = []
    @Published var currentRoom: ChatRoom?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var typingUsers: [String] = []

    private let chatService: ChatService
    private let socketManager = SocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(chatService: ChatService = ChatService()) {
        self.chatService = chatService
    }

    // MARK: - Socket Handlers

    private func setupSocketHandlers() {
        print("🔧 Setting up socket handlers for ChatViewModel instance: \(ObjectIdentifier(self))")
        
        socketManager.onNewMessage = { [weak self] message in
            guard let self = self else { 
                print("❌ Self is nil in onNewMessage handler")
                return 
            }
            print("📨 Received new message in ViewModel: \(message.content)")
            print("   Message ID: \(message.id)")
            print("   Sender: \(message.senderName)")
            print("   Has reply: \(message.replyTo != nil)")
            
            DispatchQueue.main.async {
                print("   Current messages count: \(self.messages.count)")
                
                // Check if message already exists to avoid duplicates
                if !self.messages.contains(where: { $0.id == message.id }) {
                    // Force UI update notification BEFORE adding
                    self.objectWillChange.send()
                    self.messages.append(message)
                    print("✅ Message added to array. Total messages: \(self.messages.count)")
                    print("   Messages array updated, SwiftUI should refresh")
                } else {
                    print("⚠️ Message already exists, skipping")
                }
            }
        }

        socketManager.onReactionUpdate = { [weak self] updatedMessage in
            guard let self = self else { 
                print("❌ Self is nil in onReactionUpdate handler")
                return 
            }
            print("👍 Received reaction update for message: \(updatedMessage.id)")
            print("   Reactions in update: \(updatedMessage.reactions?.count ?? 0)")
            if let reactions = updatedMessage.reactions {
                for reaction in reactions {
                    print("   - \(reaction.emoji) by \(reaction.userName)")
                }
            }
            
            DispatchQueue.main.async {
                if let index = self.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    print("   Found message at index: \(index)")
                    print("   Old reactions count: \(self.messages[index].reactions?.count ?? 0)")
                    
                    // Force UI update notification BEFORE updating
                    self.objectWillChange.send()
                    self.messages[index] = updatedMessage
                    
                    print("✅ Reaction updated. New reactions count: \(self.messages[index].reactions?.count ?? 0)")
                    print("   SwiftUI should refresh the message bubble")
                } else {
                    print("⚠️ Message not found in array for reaction update")
                    print("   Looking for ID: \(updatedMessage.id)")
                    print("   Available IDs: \(self.messages.map { $0.id })")
                }
            }
        }

        socketManager.onTyping = { [weak self] userName in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !self.typingUsers.contains(userName) {
                    self.objectWillChange.send()
                    self.typingUsers.append(userName)
                }
            }
        }

        socketManager.onStopTyping = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.typingUsers.removeAll()
            }
        }
    }

    // MARK: - Rooms

    func loadRooms() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedRooms = try await chatService.fetchRooms()
            await MainActor.run {
                self.rooms = fetchedRooms
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createRoom(name: String, description: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let newRoom = try await chatService.createRoom(name: name, description: description)
            await MainActor.run {
                self.rooms.append(newRoom)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func selectRoom(_ room: ChatRoom) {
        if let previous = currentRoom, previous.id != room.id {
            socketManager.leaveRoom(roomId: previous.id)
        }

        currentRoom = room
        socketManager.joinRoom(roomId: room.id)

        Task { await loadMessages(roomId: room.id) }
    }

    // MARK: - Messages

    func loadMessages(roomId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedMessages = try await chatService.fetchMessages(roomId: roomId)
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
        roomId: String,
        replyTo: ReplyInfo? = nil
    ) {
        socketManager.sendMessage(
            senderId: senderId,
            senderName: senderName,
            content: content,
            roomId: roomId,
            replyTo: replyTo
        )
    }

    // MARK: - Voice Messages (CORRIGÉE)

    func sendVoiceMessage(
        audioURL: URL,
        duration: TimeInterval,
        senderId: String,
        senderName: String,
        roomId: String
    ) async {   // <-- LA CORRECTION CRUCIALE EST ICI

        do {
            let uploadResponse = try await chatService.uploadAudio(fileURL: audioURL)
            let durationString = String(format: "%.1f", duration)

            socketManager.sendMessage(
                senderId: senderId,
                senderName: senderName,
                content: uploadResponse.transcription.isEmpty ? "Voice message" : uploadResponse.transcription,
                roomId: roomId,
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

    func sendTyping(userName: String) {
        guard let roomId = currentRoom?.id else { return }
        socketManager.sendTyping(roomId: roomId, userName: userName)
    }

    func sendStopTyping() {
        guard let roomId = currentRoom?.id else { return }
        socketManager.sendStopTyping(roomId: roomId)
    }

    // MARK: - Reactions

    func addReaction(messageId: String, emoji: String, userId: String, userName: String, roomId: String) {
        print("➕ Adding reaction: \(emoji) to message: \(messageId) in room: \(roomId)")
        
        // Optimistic update - immediately show the reaction in UI
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updatedMessage = messages[index]
            var reactions = updatedMessage.reactions ?? []
            
            // Check if user already reacted with this emoji
            if !reactions.contains(where: { $0.userId == userId && $0.emoji == emoji }) {
                reactions.append(Reaction(emoji: emoji, userId: userId, userName: userName))
                updatedMessage.reactions = reactions
                
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                    self.messages[index] = updatedMessage
                }
            }
        }
        
        socketManager.addReaction(
            messageId: messageId,
            emoji: emoji,
            userId: userId,
            userName: userName,
            roomId: roomId
        )
    }

    func removeReaction(messageId: String, emoji: String, userId: String, roomId: String) {
        print("➖ Removing reaction: \(emoji) from message: \(messageId) in room: \(roomId)")
        
        // Optimistic update - immediately remove the reaction from UI
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var updatedMessage = messages[index]
            var reactions = updatedMessage.reactions ?? []
            
            reactions.removeAll { $0.userId == userId && $0.emoji == emoji }
            updatedMessage.reactions = reactions
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.messages[index] = updatedMessage
            }
        }
        
        socketManager.removeReaction(
            messageId: messageId,
            emoji: emoji,
            userId: userId,
            roomId: roomId
        )
    }

    // MARK: - Lifecycle

    func connect(roomId: String, userId: String, userName: String) {
        print("🔌 Connecting to chat - Room: \(roomId), User: \(userName)")
        
        // Set up socket handlers for this ViewModel instance
        setupSocketHandlers()
        
        // Connect to socket if needed
        if !socketManager.isConnected {
            socketManager.connectChat()
        }
        
        socketManager.joinRoom(roomId: roomId)
    }

    func disconnect(roomId: String) {
        print("👋 Disconnecting from room: \(roomId)")
        socketManager.leaveRoom(roomId: roomId)
        // Do NOT disconnect the socket here, as it's a shared connection
        // socketManager.disconnectChat()
    }

    func sendTypingIndicator(userName: String) {
        guard let roomId = currentRoom?.id else { return }
        socketManager.sendTyping(roomId: roomId, userName: userName)
    }

    // MARK: - Room Calls

    func startRoomCall(userId: String, userName: String) {
        guard let roomId = currentRoom?.id else { return }
        socketManager.startRoomCall(roomId: roomId, callerId: userId, callerName: userName)
    }

    func joinRoomCall(userId: String, userName: String) {
        guard let roomId = currentRoom?.id else { return }
        socketManager.joinRoomCall(roomId: roomId, userId: userId, userName: userName)
    }

    func leaveRoomCall(userId: String, userName: String) {
        guard let roomId = currentRoom?.id else { return }
        socketManager.leaveRoomCall(roomId: roomId, userId: userId, userName: userName)
    }
}
