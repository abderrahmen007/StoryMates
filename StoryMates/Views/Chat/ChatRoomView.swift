import SwiftUI

struct ChatRoomView: View {
    let room: ChatRoom
    
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var replyingTo: ChatMessage?
    
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
                                MessageBubbleView(
                                    message: message,
                                    currentUserId: currentUserId,
                                    onReact: { emoji in
                                        viewModel.addReaction(
                                            messageId: messageId,
                                            emoji: emoji,
                                            userId: currentUserId,
                                            userName: currentUserName,
                                            roomId: room.id
                                        )
                                    }, onReply: { replyingTo = message }
                                )
                                .id("\(messageId)_\(message.reactions?.count ?? 0)")
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
            
            // Reply Preview
            if let replyingTo = replyingTo {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Replying to \(replyingTo.senderName)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(replyingTo.content)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: { self.replyingTo = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
            
            // Input Area
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
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: VoiceRoomView(
                    roomID: room.id,
                    userID: currentUserId,
                    userName: currentUserName,
                    isCallDeclined: .constant(false)
                )) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .task {
            await viewModel.loadMessages(roomId: room.id)
            viewModel.connect(roomId: room.id, userId: currentUserId, userName: currentUserName)
        }
        .onDisappear {
            viewModel.disconnect(roomId: room.id)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let replyInfo = replyingTo.map { reply in
            ReplyInfo(
                messageId: reply.id!,
                content: reply.content,
                senderName: reply.senderName
            )
        }
        
        viewModel.sendMessage(
            senderId: currentUserId,
            senderName: currentUserName,
            content: messageText,
            roomId: room.id,
            replyTo: replyInfo
        )
        
        messageText = ""
        replyingTo = nil
    }
    
    private func toggleRecording() {
        if isRecording {
            // Stop recording
            let result = audioRecorder.stopRecording()
            isRecording = false
            
            if let audioURL = result.url {
                // Upload and send voice message
                Task {
                    await viewModel.sendVoiceMessage(
                        audioURL: audioURL,
                        duration: result.duration,
                        senderId: currentUserId,
                        senderName: currentUserName,
                        roomId: room.id
                    )
                }
            }
        } else {
            // Start recording
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
                    proxy.scrollTo("\(lastId)_\(lastMessage.reactions?.count ?? 0)", anchor: .bottom)
                }
            }
        }
    }
}
