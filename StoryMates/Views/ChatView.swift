import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ConversationViewModel()
    let userId: String

    @State private var showDrawer: Bool = false
    @State private var editingMessageId: String?
    @State private var isEditingMode = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Main chat area
            VStack(spacing: 0) {
                TopBar(title: vm.selectedConversation?.title ?? "NEW QUEST", onMenuClick: {
                    withAnimation { showDrawer.toggle() }
                })

                if let err = vm.error {
                    Text(err)
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                }

                ChatScrollView(vm: vm, userId: userId, editingMessageId: $editingMessageId, isEditingMode: $isEditingMode)
                    .environmentObject(vm)

                InputBar()
                    .environmentObject(vm)
            }
            .background(
                Image("background_general")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )

            // Drawer overlay
            if showDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showDrawer = false } }

                DrawerContent(
                    conversations: vm.conversations,
                    onConversationClick: { conv in
                        vm.selectConversation(conv, userId: userId)
                        withAnimation { showDrawer = false }
                    },
                    onClose: { withAnimation { showDrawer = false } }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: showDrawer)
        .onAppear {
            vm.loadConversations(userId: userId)
        }
    }
}

// MARK: - Top Bar
struct TopBar: View {
    let title: String
    let onMenuClick: () -> Void

    var body: some View {
        HStack {
            Button(action: onMenuClick) {
                Image("burger_icon")
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            Spacer()
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 18))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
    }
}

// MARK: - Chat Scroll View
struct ChatScrollView: View {
    @ObservedObject var vm: ConversationViewModel
    let userId: String
    @Binding var editingMessageId: String?
    @Binding var isEditingMode: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.messages) { msg in
                        if msg.sender == "user" {
                            userBubble(msg)
                        } else {
                            aiBubble(msg)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _ in
                if let last = vm.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private func userBubble(_ msg: Message) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(msg.content)
                    .font(.custom("PressStart2P-Regular", size: 9))
                    .padding(12)
                    .background(
                        Image("container")
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
                    .fixedSize(horizontal: false, vertical: true)

                Menu {
                    Button("Edit") {
                        vm.messageInput = msg.content
                        editingMessageId = msg.id
                        isEditingMode = true
                    }
                    Button("Delete", role: .destructive) {
                        vm.deleteMessage(messageId: msg.id, userId: userId)
                    }
                } label: {
                    Image("drop_down_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func aiBubble(_ msg: Message) -> some View {
        HStack {
            Text(msg.content)
                .font(.custom("PressStart2P-Regular", size: 9))
                .padding(12)
                .background(
                    Image("container")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Input Bar
struct InputBar: View {
    @EnvironmentObject var viewModel: ConversationViewModel

    var body: some View {
        ZStack {
            Image("container")
                .resizable()
                .scaledToFill()
                .frame(height: 55)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            HStack(spacing: 12) {
//                Button(action: { print("Camera tapped") }) {
//                    Image("add_image_button")
//                        .resizable()
//                        .frame(width: 32, height: 32)
//                }

                TextField("Type your message…", text: $viewModel.messageInput)
                    .font(.custom("PressStart2P-Regular", size: 12))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.45), lineWidth: 1)
                    )
                    .foregroundColor(.white)

                Button(action: { viewModel.sendMessage(userId: "user_id") }) {
                    Image("send")
                        .resizable()
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 65)
        .padding(.horizontal)
        .padding(.bottom, 40)
    }
}

// MARK: - Drawer Content
struct DrawerContent: View {
    let conversations: [Conversation]
    let onConversationClick: (Conversation) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image("x_icon")
                        .resizable()
                        .frame(width: 28, height: 28)
                }
            }
            .padding(.bottom, 12)

            Text("HISTORY")
                .font(.custom("PressStart2P-Regular", size: 14))
                .padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(conversations) { conv in
                        Button(action: { onConversationClick(conv) }) {
                            ZStack {
                                Image("container")
                                    .resizable()
                                    .frame(height: 60)
                                    .cornerRadius(8)
                                Text(conv.title)
                                    .font(.custom("PressStart2P-Regular", size: 12))
                                    .foregroundColor(.black)
                                    .padding(.leading, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(width: 260)
        .padding(16)
        .background(Color(red: 254/255, green: 238/255, blue: 176/255))
    }
}
