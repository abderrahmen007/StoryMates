import SwiftUI

/// Direct Message View - Simple implementation matching Android
/// No reactions, no replies (backend doesn't support these for DMs)
struct DirectMessageView: View {
    let conversation: DirectConversation
    
    @StateObject private var viewModel = DirectMessageViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    
    @State private var messageText = ""
    @State private var isRecording = false
    
    private let currentUserId = AuthManager.shared.userId ?? "unknown"
    private let currentUserName = AuthManager.shared.userName ?? "User"
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            if let messageId = message.id {
                                DirectMessageBubble(
                                    message: message,
                                    currentUserId: currentUserId
                                )
                                .id(messageId)
                            }
                        }
                    }
                    .padding()
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Typing Indicator
            if !viewModel.typingUsers.isEmpty {
                HStack {
                    Text("\(viewModel.typingUsers.joined(separator: ", ")) typing...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
            
            // Input Area (Simple - no reply, matching Android)
            HStack(spacing: 12) {
                // Voice Recording Button
                Button(action: toggleRecording) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(isRecording ? .red : .blue)
                }
                
                // Text Input
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: messageText) { oldValue, newValue in
                        viewModel.sendTypingIndicator(userName: currentUserName)
                    }
                
                // Send Button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.displayName(currentUserId: currentUserId))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if conversation.isOtherUserOnline(currentUserId: currentUserId) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    
                    Button {
                        if let otherParticipant = conversation.otherParticipant(currentUserId: currentUserId) {
                            CallManager.shared.startCall(
                                callerId: currentUserId,
                                callerName: currentUserName,
                                calleeId: otherParticipant.userId,
                                calleeName: otherParticipant.userName,
                                roomId: conversation.id
                            )
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .alert("Call Declined", isPresented: Binding(
            get: { CallManager.shared.isCallDeclined },
            set: { CallManager.shared.isCallDeclined = $0 }
        )) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await viewModel.loadMessages(conversationId: conversation.id)
            viewModel.connect(conversationId: conversation.id, userId: currentUserId, userName: currentUserName)
            viewModel.markAsRead(conversationId: conversation.id, userId: currentUserId)
        }
        .onDisappear {
            viewModel.disconnect(conversationId: conversation.id, userId: currentUserId)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        viewModel.sendMessage(
            senderId: currentUserId,
            senderName: currentUserName,
            content: messageText,
            conversationId: conversation.id
        )
        
        messageText = ""
    }
    
    private func toggleRecording() {
        if isRecording {
            let result = audioRecorder.stopRecording()
            isRecording = false
            
            if let audioURL = result.url {
                Task {
                    await viewModel.sendVoiceMessage(
                        audioURL: audioURL,
                        duration: result.duration,
                        senderId: currentUserId,
                        senderName: currentUserName,
                        conversationId: conversation.id
                    )
                }
            }
        } else {
            audioRecorder.requestPermission { granted in
                if granted {
                    do {
                        _ = try audioRecorder.startRecording()
                        isRecording = true
                    } catch {
                        print("Failed to start recording: \(error)")
                    }
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last, let lastId = lastMessage.id {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Simple Message Bubble for DMs (matching Android)
struct DirectMessageBubble: View {
    let message: ChatMessage
    let currentUserId: String
    
    private var isCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                if let audioUrl = message.audioUrl {
                    VoiceMessageView(
                        audioUrl: audioUrl,
                        duration: message.duration ?? "0",
                        transcription: message.transcription
                    )
                } else {
                    Text(message.content)
                        .padding(12)
                        .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                }
                
                // Timestamp
                Text(formatDate(message.createdAt ?? ""))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal)
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString, !dateString.isEmpty else { return "" }
        
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        return displayFormatter.string(from: date)
    }
}
