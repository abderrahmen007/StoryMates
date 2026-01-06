import SwiftUI

struct IncomingCallView: View {
    let callerName: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        ZStack {
            // Background with blur effect
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Caller Info
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(String(callerName.prefix(1)))
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(callerName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Incoming Voice Call...")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 60) {
                    // Decline Button
                    Button(action: onDecline) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "phone.down.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                            Text("Decline")
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Accept Button
                    Button(action: onAccept) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                            Text("Accept")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    IncomingCallView(callerName: "Chams", onAccept: {}, onDecline: {})
}
