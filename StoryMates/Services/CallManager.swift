import SwiftUI
import Combine

class CallManager: ObservableObject {
    static let shared = CallManager()
    
    @Published var incomingCall: CallData?
    @Published var isShowingIncomingCall = false
    @Published var activeCall: CallData?
    @Published var isCallDeclined = false
    
    struct CallData: Identifiable {
        let id = UUID()
        let callId: String
        let callerId: String
        let callerName: String
        let isRoomCall: Bool
    }
    
    private init() {
        setupListeners()
    }
    
    func setupListeners() {
        SocketIOManager.shared.onIncomingCall = { [weak self] callerId, callerName, roomId in
            DispatchQueue.main.async {
                print("📞 CallManager: Received DM call from \(callerName)")
                self?.incomingCall = CallData(
                    callId: roomId,
                    callerId: callerId,
                    callerName: callerName,
                    isRoomCall: false
                )
                self?.isShowingIncomingCall = true
            }
        }
        
        SocketIOManager.shared.onIncomingRoomCall = { [weak self] callerId, callerName, roomId in
            DispatchQueue.main.async {
                print("📞 CallManager: Received Room call from \(callerName)")
                self?.incomingCall = CallData(
                    callId: roomId,
                    callerId: callerId,
                    callerName: callerName,
                    isRoomCall: true
                )
                self?.isShowingIncomingCall = true
            }
        }
        
        SocketIOManager.shared.onCallCancelled = { [weak self] in
            DispatchQueue.main.async {
                print("🚫 CallManager: Call cancelled")
                self?.isShowingIncomingCall = false
                self?.incomingCall = nil
                self?.activeCall = nil
            }
        }
        
        SocketIOManager.shared.onCallEnded = { [weak self] in
            DispatchQueue.main.async {
                print("📴 CallManager: Call ended")
                self?.isShowingIncomingCall = false
                self?.incomingCall = nil
                self?.activeCall = nil
            }
        }
    }
    
    func acceptCall() {
        guard let call = incomingCall else { return }
        print("✅ CallManager: Accepting call \(call.callId)")
        
        if !call.isRoomCall {
            SocketIOManager.shared.acceptCall(
                callId: call.callId,
                callerId: call.callerId,
                calleeId: AuthManager.shared.userId ?? "",
                calleeName: AuthManager.shared.userName ?? "User"
            )
        }
        
        activeCall = call
        isShowingIncomingCall = false
        incomingCall = nil
    }
    
    func declineCall() {
        guard let call = incomingCall else { return }
        print("❌ CallManager: Declining call \(call.callId)")
        
        if !call.isRoomCall {
            SocketIOManager.shared.declineCall(
                callId: call.callId,
                callerId: call.callerId,
                calleeId: AuthManager.shared.userId ?? "",
                calleeName: AuthManager.shared.userName ?? "User"
            )
        }
        
        isShowingIncomingCall = false
        incomingCall = nil
        isCallDeclined = true
        
        // Reset decline state after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isCallDeclined = false
        }
    }
    
    func endCall() {
        guard let call = activeCall else { return }
        print("📴 CallManager: Ending call \(call.callId)")
        
        if !call.isRoomCall {
            SocketIOManager.shared.endCall(
                callId: call.callId,
                userId: AuthManager.shared.userId ?? "",
                otherUserId: call.callerId
            )
        } else {
            // Room call leave
            SocketIOManager.shared.leaveRoomCall(
                roomId: call.callId,
                userId: AuthManager.shared.userId ?? "",
                userName: AuthManager.shared.userName ?? "User"
            )
        }
        
        activeCall = nil
    }
    
    func startCall(callerId: String, callerName: String, calleeId: String, calleeName: String, roomId: String) {
        print("📞 CallManager: Starting call to \(calleeName)")
        SocketIOManager.shared.requestCall(
            callId: roomId,
            callerId: callerId,
            callerName: callerName,
            calleeId: calleeId,
            calleeName: calleeName,
            conversationId: roomId
        )
        
        activeCall = CallData(
            callId: roomId,
            callerId: callerId,
            callerName: callerName,
            isRoomCall: false
        )
    }
}
