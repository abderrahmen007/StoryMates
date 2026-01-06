import SwiftUI

struct ReactionPickerView: View {
    let onSelect: (String) -> Void
    
    private let emojis = ["👍", "❤️", "😂", "😮", "😢", "🙏"]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(emojis, id: \.self) { emoji in
                Button(action: {
                    onSelect(emoji)
                }) {
                    Text(emoji)
                        .font(.system(size: 24))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
