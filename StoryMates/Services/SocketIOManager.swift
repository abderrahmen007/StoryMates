import Foundation

// MARK: - Socket.IO Manager
// Note: This requires the socket.io-client-swift package
// Add via Xcode: File > Add Package Dependencies > https://github.com/socketio/socket.io-client-swift

// Uncomment the imports below after adding the Socket.IO package:
import SocketIO
import Combine

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    // Uncomment after adding Socket.IO package
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var notificationSocket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var isNotificationConnected = false
    
    private let baseURL: String
    
    private init(baseURL: String = "http://localhost:3001") {
        self.baseURL = baseURL
    }
    
    // MARK: - Chat Socket Methods
    
    func connectChat() {
        // TODO: Implement after adding Socket.IO package
        guard let url = URL(string: baseURL) else { return }
        
        // Disconnect existing socket if any to prevent duplicates
        if socket != nil {
            socket?.disconnect()
            socket?.removeAllHandlers()
        }
        
        manager = SocketManager(socketURL: url, config: [.log(true), .compress])
        socket = manager?.defaultSocket
        
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Chat socket connected")
            self?.isConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("⚠️ Chat socket disconnected")
            self?.isConnected = false
        }
        
        socket?.on("newMessage") { [weak self] data, ack in
            self?.handleNewMessage(data: data)
        }
        
        socket?.on("new-direct-message") { [weak self] data, ack in
            self?.handleNewDirectMessage(data: data)
        }
        
        socket?.on("messageReactionUpdated") { [weak self] data, ack in
            self?.handleReactionUpdate(data: data)
        }
        
        socket?.on("typing") { [weak self] data, ack in
            self?.handleTyping(data: data)
        }
        
        socket?.on("stopTyping") { [weak self] data, ack in
            self?.handleStopTyping(data: data)
        }
        
        socket?.on("user-typing-direct") { [weak self] data, ack in
            if let userName = data[0] as? String {
                self?.onTypingInConversation?(userName)
            }
        }
        
        socket?.on("messages-read") { [weak self] data, ack in
             if let response = data[0] as? [String: Any], let userId = response["userId"] as? String {
                 self?.onMessageRead?("unknown") 
             }
        }
        
        // Incoming calls are handled in listenForCalls(userId:) which is more specific.
        // We can keep these as fallback or remove if and only if they match.
        // Let's remove to avoid confusion as we use user-specific channels now.
        
        
        
        socket?.connect()
    }

    /// Listen for user-specific call events. Call this after login.
    func listenForCalls(userId: String) {
        // Listen for incoming calls (user-specific event)
        socket?.on("incoming-call-\(userId)") { [weak self] data, ack in
            self?.handleIncomingCall(data: data)
        }
        
        // Listen for call accepted (user-specific)
        socket?.on("call-accepted-\(userId)") { [weak self] data, ack in
             print("📞 Call accepted by callee")
             self?.onCallAccepted?()
        }
        
        // Listen for call declined (user-specific)
        socket?.on("call-declined-\(userId)") { [weak self] data, ack in
            print("❌ Call declined by callee")
            self?.onCallDeclined?()
        }

        // Listen for call cancelled (user-specific)
        socket?.on("call-cancelled-\(userId)") { [weak self] data, ack in
            print("🚫 Call cancelled by caller")
            self?.onCallCancelled?()
        }

        // Listen for call ended (user-specific)
        socket?.on("call-ended-\(userId)") { [weak self] data, ack in
            print("📴 Call ended by other party")
            self?.onCallEnded?()
        }
        
        print("🎧 Listening for calls on channel: incoming-call-\(userId)")
    }
    
    func disconnectChat() {
        // TODO: Implement after adding Socket.IO package
        socket?.disconnect()
    }
    
    func joinRoom(roomId: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("joinRoom", roomId)
        print("📍 Join room: \(roomId)")
    }
    
    func leaveRoom(roomId: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("leaveRoom", roomId)
        print("👋 Leave room: \(roomId)")
    }
    
    func sendMessage(senderId: String, senderName: String, content: String, roomId: String, audioUrl: String? = nil, transcription: String? = nil, duration: String? = nil, replyTo: ReplyInfo? = nil) {
        // TODO: Implement after adding Socket.IO package
        var payload: [String: Any] = [
            "senderId": senderId,
            "senderName": senderName,
            "content": content,
            "roomId": roomId
        ]
        
        if let audioUrl = audioUrl {
            payload["audioUrl"] = audioUrl
        }
        if let transcription = transcription {
            payload["transcription"] = transcription
        }
        if let duration = duration {
            payload["duration"] = duration
        }
        if let replyTo = replyTo {
            payload["replyTo"] = [
                "messageId": replyTo.messageId,
                "content": replyTo.content,
                "senderName": replyTo.senderName
            ]
        }
        
        socket?.emit("sendMessage", payload)
        print("📤 Send message to room: \(roomId)")
    }
    
    func sendTyping(roomId: String, userName: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("typing", [
            "roomId": roomId,
            "userName": userName
        ])
    }
    
    func sendStopTyping(roomId: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("stopTyping", [
            "roomId": roomId
        ])
    }
    
    func addReaction(messageId: String, emoji: String, userId: String, userName: String, roomId: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("addReaction", [
            "messageId": messageId,
            "emoji": emoji,
            "userId": userId,
            "userName": userName,
            "roomId": roomId
        ])
        print("👍 Add reaction: \(emoji) to message: \(messageId)")
    }
    
    func removeReaction(messageId: String, emoji: String, userId: String, roomId: String) {
        // TODO: Implement after adding Socket.IO package
        socket?.emit("removeReaction", [
            "messageId": messageId,
            "emoji": emoji,
            "userId": userId,
            "roomId": roomId
        ])
        print("👎 Remove reaction: \(emoji) from message: \(messageId)")
    }
    
    // MARK: - Notification Socket Methods
    
    func connectNotifications() {
        // TODO: Implement after adding Socket.IO package
        guard let url = URL(string: baseURL) else { return }
        
        if manager == nil {
            manager = SocketManager(socketURL: url, config: [.log(true), .compress])
        }
        
        notificationSocket = manager?.socket(forNamespace: "/notifications")
        
        notificationSocket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Notification socket connected")
            self?.isNotificationConnected = true
        }
        
        notificationSocket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("⚠️ Notification socket disconnected")
            self?.isNotificationConnected = false
        }
        
        notificationSocket?.on("newNotification") { [weak self] data, ack in
            self?.handleNewNotification(data: data)
        }
        
        notificationSocket?.connect()
    }
    
    func disconnectNotifications() {
        // TODO: Implement after adding Socket.IO package
        notificationSocket?.disconnect()
    }
    
    func joinNotificationRoom(userId: String) {
        // TODO: Implement after adding Socket.IO package
        notificationSocket?.emit("joinNotificationRoom", userId)
        print("📍 Join notification room for user: \(userId)")
    }
    
    func leaveNotificationRoom(userId: String) {
        // TODO: Implement after adding Socket.IO package
        notificationSocket?.emit("leaveNotificationRoom", userId)
        print("👋 Leave notification room for user: \(userId)")
    }
    
    // MARK: - Direct Message Socket Methods
    
    func joinUserRoom(userId: String) {
        socket?.emit("joinUserRoom", userId)
        print("📍 Join user room: user_\(userId)")
    }
    
    func joinConversation(conversationId: String) {
        socket?.emit("join-direct-conversation", ["conversationId": conversationId])
        print("🔌 Joining direct conversation: \(conversationId)")
    }
    
    func leaveConversation(conversationId: String) {
        socket?.emit("leave-direct-conversation", ["conversationId": conversationId])
        print("👋 Leaving direct conversation: \(conversationId)")
    }
    
    func sendDirectMessage(
        senderId: String,
        senderName: String,
        content: String,
        conversationId: String,
        type: String = "text",
        audioUrl: String? = nil,
        transcription: String? = nil,
        duration: String? = nil,
        replyTo: ReplyInfo? = nil
    ) {
        var payload: [String: Any] = [
            "conversationId": conversationId,
            "senderId": senderId,
            "content": content,
            "type": type
        ]
        
        if let audioUrl = audioUrl { payload["audioUrl"] = audioUrl }
        if let transcription = transcription { payload["transcription"] = transcription }
        if let duration = duration { payload["duration"] = duration }
        
        if let replyTo = replyTo {
            payload["replyTo"] = [
                "messageId": replyTo.messageId,
                "content": replyTo.content,
                "senderName": replyTo.senderName
            ]
        }
        
        socket?.emit("send-direct-message", payload)
        print("📨 Sending direct message to: \(conversationId)")
    }
    
    func markMessagesAsRead(conversationId: String, userId: String) {
        socket?.emit("mark-read-direct", ["conversationId": conversationId, "userId": userId])
        print("✅ Mark messages as read in conversation: \(conversationId)")
    }
    
    func updateOnlineStatus(userId: String, isOnline: Bool) {
        socket?.emit("updateOnlineStatus", [
            "userId": userId,
            "isOnline": isOnline
        ])
        print("🟢 Update online status: \(isOnline)")
    }
    
    func sendTypingInConversation(conversationId: String, userName: String) {
        socket?.emit("typing-direct", ["conversationId": conversationId, "userName": userName])
    }
    
    func sendStopTypingInConversation(conversationId: String) {
        socket?.emit("typing-direct", ["conversationId": conversationId, "userName": ""]) // Empty name to signify stop
        print("⌨️ Stop typing indicator for: \(conversationId)")
    }
    
    // MARK: - Event Handlers
    
    var onNewMessage: ((ChatMessage) -> Void)?
    var onReactionUpdate: ((ChatMessage) -> Void)?
    var onDirectMessageReactionUpdate: ((ChatMessage) -> Void)? // Separate handler for DM reactions
    var onTyping: ((String) -> Void)?
    var onStopTyping: (() -> Void)?
    var onNewNotification: ((AppNotification) -> Void)?
    
    // Publisher for notifications - allows multiple subscribers
    let notificationPublisher = PassthroughSubject<AppNotification, Never>()
    
    // DM-specific handlers
    var onDirectMessage: ((ChatMessage) -> Void)?
    var onUserOnlineStatus: ((String, Bool) -> Void)?
    var onMessageRead: ((String) -> Void)?
    var onTypingInConversation: ((String) -> Void)?
    var onStopTypingInConversation: (() -> Void)?
    var onIncomingCall: ((String, String, String) -> Void)? // callerId, callerName, roomId
    var onCallAccepted: (() -> Void)?
    var onCallDeclined: (() -> Void)?
    var onCallCancelled: (() -> Void)?
    var onCallEnded: (() -> Void)?
    
    // ... (existing handlers)
    
    func requestCall(callId: String, callerId: String, callerName: String, calleeId: String, calleeName: String, conversationId: String) {
        let payload: [String: Any] = [
            "callId": callId,
            "callerId": callerId,
            "callerName": callerName,
            "calleeId": calleeId,
            "calleeName": calleeName,
            "conversationId": conversationId
        ]
        
        socket?.emit("call-request", payload)
        print("📞 Emission call-request to \(calleeId)")
    }
    
    func declineCall(callId: String, callerId: String, calleeId: String, calleeName: String) {
        let payload: [String: Any] = [
            "callId": callId,
            "callerId": callerId,
            "calleeId": calleeId,
            "calleeName": calleeName
        ]
        socket?.emit("call-declined", payload)
        print("📞 Emission call-declined to \(callerId)")
    }
    
    func acceptCall(callId: String, callerId: String, calleeId: String, calleeName: String) {
        let payload: [String: Any] = [
            "callId": callId,
            "callerId": callerId,
            "calleeId": calleeId,
            "calleeName": calleeName
        ]
        socket?.emit("call-accepted", payload)
        print("📞 Emission call-accepted")
    }
    
    func cancelCall(callId: String, callerId: String, calleeId: String) {
        let payload: [String: Any] = [
            "callId": callId,
            "callerId": callerId,
            "calleeId": calleeId
        ]
        socket?.emit("call-cancelled", payload)
        print("📞 Emission call-cancelled")
    }
    
    func endCall(callId: String, userId: String, otherUserId: String) {
        let payload: [String: Any] = [
            "callId": callId,
            "userId": userId,
            "otherUserId": otherUserId
        ]
        socket?.emit("call-ended", payload)
        print("📞 Emission call-ended")
    }
    
    private func handleNewMessage(data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        print("🔍 Raw newMessage payload: \(messageData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            onNewMessage?(message)
            print("📨 New message received: \(message.content)")
            if let reply = message.replyTo {
                print("   ↪️ With reply to: \(reply.senderName)")
            } else {
                print("   ❌ ReplyTo is nil in decoded message")
            }
        } catch {
            print("❌ Error decoding message: \(error)")
        }
    }
    
    private func handleNewDirectMessage(data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        print("🔍 Raw newDirectMessage payload: \(messageData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            onDirectMessage?(message)
            print("📨 New direct message received: \(message.content)")
        } catch {
            print("❌ Error decoding direct message: \(error)")
        }
    }
    
    private func handleReactionUpdate(data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        print("🔍 Raw reactionUpdate payload: \(messageData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            // Call both handlers - the appropriate ViewModel will handle it based on message context
            onReactionUpdate?(message)
            onDirectMessageReactionUpdate?(message)
            
            print("👍 Reaction updated for message: \(message.id ?? "unknown")")
            print("   Reactions count: \(message.reactions?.count ?? 0)")
        } catch {
            print("❌ Error decoding reaction update: \(error)")
        }
    }
    
    private func handleTyping(data: [Any]) {
        guard let typingData = data.first as? [String: Any],
              let userName = typingData["userName"] as? String else { return }
        
        onTyping?(userName)
        print("⌨️ User typing: \(userName)")
    }
    
    private func handleStopTyping(data: [Any]) {
        onStopTyping?()
        print("⌨️ User stopped typing")
    }
    
    private func handleNewNotification(data: [Any]) {
        guard let notificationData = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationData)
            let notification = try JSONDecoder().decode(AppNotification.self, from: jsonData)
            
            // Call the callback handler (for backward compatibility)
            onNewNotification?(notification)
            
            // Also publish to the Combine publisher (for multiple subscribers)
            notificationPublisher.send(notification)
            
            print("🔔 New notification received: \(notification.type)")
        } catch {
            print("❌ Error decoding notification: \(error)")
        }
    }
    
    private func handleIncomingCall(data: [Any]) {
        // Android sends full call request object.
        // We need to parse: callerId, callerName, roomId (or callId)
        guard let callData = data.first as? [String: Any] else { return }
              
        let callerId = callData["callerId"] as? String ?? ""
        let callerName = callData["callerName"] as? String ?? "Unknown"
        // Backend uses conversationId for DMs, Rooms might use roomId
        let roomId = (callData["conversationId"] as? String) ?? (callData["roomId"] as? String) ?? ""
        
        print("📞 Incoming call from: \(callerName) in room/conv: \(roomId)")
        onIncomingCall?(callerId, callerName, roomId)
    }
    
    private func handleCallDeclined(data: [Any]) {
        print("📞 Call declined by user")
        onCallDeclined?()
    }
    
    // MARK: - Room Call Methods
    
    func startRoomCall(roomId: String, callerId: String, callerName: String) {
        let callId = UUID().uuidString
        let payload: [String: Any] = [
            "roomId": roomId,
            "callerId": callerId,
            "callerName": callerName,
            "callId": callId
        ]
        socket?.emit("start-room-call", payload)
        print("📞 Starting room call in: \(roomId)")
    }
    
    func joinRoomCall(roomId: String, userId: String, userName: String) {
        let payload: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "userName": userName
        ]
        socket?.emit("join-room-call", payload)
        print("📞 Joining room call: \(roomId)")
    }
    
    func leaveRoomCall(roomId: String, userId: String, userName: String) {
        let payload: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "userName": userName
        ]
        socket?.emit("leave-room-call", payload)
        print("📞 Leaving room call: \(roomId)")
    }
    
    // MARK: - Room Call Listeners
    
    var onIncomingRoomCall: ((String, String, String) -> Void)? // roomId, callerName, callId
    var onUserJoinedRoomCall: ((String, String) -> Void)? // userId, userName
    var onUserLeftRoomCall: ((String, String) -> Void)? // userId, userName
    
    func listenForRoomCalls() {
        socket?.on("incoming-room-call") { [weak self] data, ack in
            guard let callData = data.first as? [String: Any],
                  let roomId = callData["roomId"] as? String,
                  let callerName = callData["callerName"] as? String,
                  let callId = callData["callId"] as? String else { return }
            
            print("📞 Incoming room call in \(roomId) from \(callerName)")
            self?.onIncomingRoomCall?(roomId, callerName, callId)
        }
        
        socket?.on("user-joined-room-call") { [weak self] data, ack in
            guard let payload = data.first as? [String: Any],
                  let userId = payload["userId"] as? String,
                  let userName = payload["userName"] as? String else { return }
            
            print("📞 User \(userName) joined room call")
            self?.onUserJoinedRoomCall?(userId, userName)
        }
        
        socket?.on("user-left-room-call") { [weak self] data, ack in
            guard let payload = data.first as? [String: Any],
                  let userId = payload["userId"] as? String,
                  let userName = payload["userName"] as? String else { return }
            
            print("📞 User \(userName) left room call")
            self?.onUserLeftRoomCall?(userId, userName)
        }
    }
}
