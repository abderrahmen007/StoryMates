import SwiftUI

struct CallOverlayView: View {
    @ObservedObject var callManager = CallManager.shared
    
    var body: some View {
        ZStack {
            if callManager.isShowingIncomingCall, let call = callManager.incomingCall {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "phone.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        Text("Incoming \(call.isRoomCall ? "Room " : "")Call")
                            .font(.headline)
                        
                        Text(call.callerName)
                            .font(.title)
                        
                        HStack(spacing: 40) {
                            Button(action: {
                                callManager.declineCall()
                            }) {
                                Image(systemName: "phone.down.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.red)
                            }
                            
                            Button(action: {
                                callManager.acceptCall()
                            }) {
                                Image(systemName: "phone.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
                .transition(.move(edge: .bottom))
                .zIndex(999)
            }
        }
        .fullScreenCover(item: Binding(
            get: { callManager.activeCall },
            set: { _ in callManager.activeCall = nil }
        )) { call in
            VoiceRoomView(
                roomID: call.callId,
                userID: AuthManager.shared.userId ?? "unknown",
                userName: AuthManager.shared.userName ?? "User",
                isCallDeclined: $callManager.isCallDeclined
            )
        }
    }
}
