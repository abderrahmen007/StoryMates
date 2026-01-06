import SwiftUI

struct PostCardView: View {
    let post: Post
    var onLike: () -> Void
    var onAddComment: (String) -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var commentText = ""
    @State private var showComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PostHeaderView(authorName: post.author?.name, onEdit: onEdit, onDelete: onDelete)
            
            // 📝 TITLE
            Text(post.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            // 📄 CONTENT
            Text(post.content)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            PostImageView(photo: post.photo)
            
            Divider()
                .padding(.horizontal, 16)
            
            PostActionsView(
                likes: post.likes.count,
                commentCount: post.comments.count,
                onLike: onLike,
                onToggleComments: { withAnimation { showComments.toggle() } }
            )
            
            if showComments {
                PostCommentsView(
                    comments: post.comments,
                    commentText: $commentText,
                    onAddComment: onAddComment
                )
            }
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PostHeaderView: View {
    let authorName: String?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(authorName?.prefix(1).uppercased() ?? "?")
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading) {
                Text(authorName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("Just now") // Placeholder for date
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct PostImageView: View {
    let photo: String?
    
    var body: some View {
        if let photo = photo, !photo.isEmpty,
           let data = Data(base64Encoded: photo.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxHeight: 300)
                .clipped()
                .cornerRadius(12)
                .padding(.horizontal, 16)
        }
    }
}

struct PostActionsView: View {
    let likes: Int
    let commentCount: Int
    let onLike: () -> Void
    let onToggleComments: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                        .foregroundColor(.red)
                    Text("\(likes)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            Button(action: onToggleComments) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.blue)
                    Text("\(commentCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

struct PostCommentsView: View {
    let comments: [Comment]
    @Binding var commentText: String
    let onAddComment: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            ForEach(comments, id: \.id) { comment in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(comment.author?.name?.prefix(1).uppercased() ?? "?")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.author?.name ?? "User")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(comment.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(20)
                
                if !commentText.isEmpty {
                    Button(action: {
                        onAddComment(commentText)
                        commentText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding(.bottom, 16)
    }
}

