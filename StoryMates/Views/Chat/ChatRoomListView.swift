import SwiftUI

struct ChatRoomListView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showCreateRoom = false
    @State private var newRoomName = ""
    @State private var newRoomDescription = ""
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading rooms...")
                } else if viewModel.rooms.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No chat rooms yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Create a room to start chatting")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button(action: { showCreateRoom = true }) {
                            Label("Create Room", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List(viewModel.rooms) { room in
                        NavigationLink(destination: ChatRoomView(room: room)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.name)
                                    .font(.headline)
                                if let description = room.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateRoom = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showCreateRoom) {
            NavigationView {
                Form {
                    Section(header: Text("Room Details")) {
                        TextField("Room Name", text: $newRoomName)
                        TextField("Description (optional)", text: $newRoomDescription)
                    }
                }
                .navigationTitle("Create Room")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showCreateRoom = false
                            newRoomName = ""
                            newRoomDescription = ""
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            Task {
                                await viewModel.createRoom(name: newRoomName, description: newRoomDescription)
                                showCreateRoom = false
                                newRoomName = ""
                                newRoomDescription = ""
                            }
                        }
                        .disabled(newRoomName.isEmpty)
                    }
                }
            }
        }
        .task {
            await viewModel.loadRooms()
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomListView()
    }
}
