import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    let currentUserId: String
    let onReact: (String) -> Void
    let onReply: () -> Void
    
    @State private var showReactionPicker = false
    
    private var isCurrentUser: Bool {
        message.senderId == currentUserId
    }
    
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            messageContent
            if !isCurrentUser { Spacer() }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showReactionPicker) {
            ReactionPickerView { emoji in
                onReact(emoji)
                showReactionPicker = false
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
            // Sender name (only for other users)
            if !isCurrentUser {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Reply preview
            if let replyTo = message.replyTo {
                replyPreview(replyTo)
            }
            
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
            
            // Reactions
            if let reactions = message.reactions, !reactions.isEmpty {
                reactionsView(reactions)
            }
            
            // Timestamp
            Text(formatDate(message.createdAt ?? ""))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .contextMenu {
            Button(action: onReply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
            Button(action: { showReactionPicker = true }) {
                Label("React", systemImage: "face.smiling")
            }
        }
    }
    
    private func replyPreview(_ replyTo: ReplyInfo) -> some View {
        HStack {
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(replyTo.senderName)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(replyTo.content)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func reactionsView(_ reactions: [Reaction]) -> some View {
        HStack(spacing: 4) {
            ForEach(groupReactions(reactions), id: \.emoji) { group in
                HStack(spacing: 2) {
                    Text(group.emoji)
                        .font(.caption)
                    if group.count > 1 {
                        Text("\(group.count)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .id(reactions.map { "\($0.emoji)_\($0.userId)" }.joined(separator: "_"))
    }
    
    private func groupReactions(_ reactions: [Reaction]) -> [(emoji: String, count: Int)] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { (emoji: $0.key, count: $0.value.count) }
    }
    
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString, !dateString.isEmpty else {
            return ""
        }
        
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "HH:mm"
        return displayFormatter.string(from: date)
    }
}
