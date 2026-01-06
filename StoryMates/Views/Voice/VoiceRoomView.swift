import SwiftUI
import ZegoUIKitPrebuiltCall
internal import ZegoUIKit

struct VoiceRoomView: View {
    let roomID: String
    let userID: String
    let userName: String
    @Binding var isCallDeclined: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    // Credentials from Android app
    private let appID: UInt32 = 1081952728
    private let appSign = "c416f40482159b1d4ed83f0de382354ae00ddbb2f611ee9d2c641b135855369f"
    
    var body: some View {
        ZegoUIKitPrebuiltCallVCRep(
            appID: appID,
            appSign: appSign,
            userID: userID,
            userName: userName,
            callID: roomID,
            config: customVoiceCallConfig(),
            onCallEnd: {
                // Dismiss the view when call ends
                dismiss()
            }
        )
        .edgesIgnoringSafeArea(.all)
        .onChange(of: isCallDeclined) { oldValue, newValue in
            if newValue {
                print("📞 Call declined, dismissing VoiceRoomView")
                dismiss()
            }
        }
    }
    
    // Custom configuration that ensures controls respect safe zones
    private func customVoiceCallConfig() -> ZegoUIKitPrebuiltCallConfig {
        let config = ZegoUIKitPrebuiltCallConfig()
        
        // Voice call settings
        config.turnOnCameraWhenJoining = false
        config.turnOnMicrophoneWhenJoining = true
        config.useSpeakerWhenJoining = true
        
        // Layout configuration
        let layout = ZegoLayout()
        layout.mode = .gallery
        layout.config = ZegoLayoutGalleryConfig()
        config.layout = layout
        
        // Bottom menu bar configuration with safe zone support
        let bottomMenuBarConfig = ZegoBottomMenuBarConfig()
        bottomMenuBarConfig.buttons = [.toggleMicrophoneButton, .hangUpButton, .switchAudioOutputButton]
        bottomMenuBarConfig.hideAutomatically = false // Keep controls visible for better accessibility
        bottomMenuBarConfig.hideByClick = true
        bottomMenuBarConfig.style = .dark
        config.bottomMenuBarConfig = bottomMenuBarConfig
        
        // Top menu bar configuration
        let topMenuBarConfig = ZegoTopMenuBarConfig()
        topMenuBarConfig.buttons = [.showMemberListButton]
        topMenuBarConfig.isVisible = true
        topMenuBarConfig.hideAutomatically = false
        topMenuBarConfig.hideByClick = true
        topMenuBarConfig.style = .dark
        config.topMenuBarConfig = topMenuBarConfig
        
        return config
    }
}

struct ZegoUIKitPrebuiltCallVCRep: UIViewControllerRepresentable {
    let appID: UInt32
    let appSign: String
    let userID: String
    let userName: String
    let callID: String
    let config: ZegoUIKitPrebuiltCallConfig
    let onCallEnd: () -> Void
    
    func makeUIViewController(context: Context) -> ZegoUIKitPrebuiltCallVC {
        let callVC = ZegoUIKitPrebuiltCallVC(
            appID,
            appSign: appSign,
            userID: userID,
            userName: userName,
            callID: callID,
            config: config
        )
        callVC.delegate = context.coordinator
        return callVC
    }
    
    func updateUIViewController(_ uiViewController: ZegoUIKitPrebuiltCallVC, context: Context) {
        // Update logic if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCallEnd: onCallEnd)
    }
    
    class Coordinator: NSObject, ZegoUIKitPrebuiltCallVCDelegate {
        let onCallEnd: () -> Void
        
        init(onCallEnd: @escaping () -> Void) {
            self.onCallEnd = onCallEnd
        }
        
        func onCallEnd(_ event: ZegoCallEndEvent) {
            // Call ended, dismiss the view
            DispatchQueue.main.async {
                self.onCallEnd()
            }
        }
    }
}
