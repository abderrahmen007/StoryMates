import SwiftUI

struct UserProfileSheet: View {
    let userId: String
    let initialName: String
    let initialAvatar: String?
    
    @State private var profile: NetworkManager.UserProfile?
    @State private var isLoading = true
    @State private var isInviting = false
    @State private var showInviteSuccess = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    // We need a network manager here. Usually passed or Singleton.
    // Assuming we can instantiate or use Environment.
    private let networkManager = NetworkManager() 
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.15).ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.yellow)
            } else if let profile = profile {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Avatar & Header
                            VStack(spacing: 16) {
                                AsyncImage(url: URL(string: profile.avatar ?? initialAvatar ?? "")) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Circle().fill(Color.gray)
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                            .font(.largeTitle)
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.yellow, lineWidth: 3))
                                .shadow(radius: 10)
                                
                                VStack(spacing: 8) {
                                    Text(profile.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    if let bio = profile.bio, !bio.isEmpty {
                                        Text(bio)
                                            .font(.body)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.top, 40)
                            
                            // Game Section
                            if let game = profile.favoriteGame {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("PLAYING NOW", systemImage: "gamecontroller.fill")
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .foregroundColor(.yellow)
                                    
                                    HStack(spacing: 16) {
                                        AsyncImage(url: URL(string: game.coverUrl)) { img in
                                            img.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 80, height: 100)
                                        .cornerRadius(8)
                                        
                                        Text(game.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Play Styles
                            if let styles = profile.playStyles, !styles.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("PLAY STYLE", systemImage: "slider.horizontal.3")
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .foregroundColor(.cyan)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(styles, id: \.self) { style in
                                                Text(style)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(Color.cyan.opacity(0.2))
                                                    .foregroundColor(.cyan)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Stats Section
                             if let stats = profile.stats {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("STATS", systemImage: "chart.bar.fill")
                                        .font(.custom("PressStart2P-Regular", size: 10))
                                        .foregroundColor(.green)
                                    
                                    HStack(spacing: 20) {
                                        StatBox(title: "Level", value: "\(stats.level)")
                                        StatBox(title: "XP", value: "\(stats.xp)")
                                        StatBox(title: "Games", value: "\(stats.totalGamesPlayed)")
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    
                    // Footer Actions
                    VStack {
                        if showInviteSuccess {
                            Text("Invite Sent!")
                                .foregroundColor(.green)
                                .padding(.bottom, 8)
                        }
                        
                        Button(action: sendInvite) {
                            HStack {
                                if isInviting {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "envelope.fill")
                                    Text(showInviteSuccess ? "SENT" : "INVITE TO GAME")
                                        .font(.custom("PressStart2P-Regular", size: 12))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showInviteSuccess ? Color.green : Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                        .disabled(isInviting || showInviteSuccess)
                        
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                }
            } else {
                Text("Failed to load profile")
                    .foregroundColor(.red)
            }
        }
        .task {
            do {
                self.profile = try await networkManager.getUserProfile(userId: userId)
                self.isLoading = false
            } catch {
                print("Error fetching profile: \(error)")
                self.isLoading = false
            }
        }
    }
    
    private func sendInvite() {
        guard let myId = authManager.userId else { return }
        isInviting = true
        
        Task {
            do {
                // Game ID? Assuming invitating to specific game logic.
                // For now, let's use a dummy gameID or pass it in.
                // Or if user has a selected game in previous screen?
                // Default to favorite game?
                let gameId = profile?.favoriteGame?.gameId ?? 0 
                
                try await networkManager.sendInvite(fromUserId: myId, toUserId: userId, gameId: gameId)
                await MainActor.run {
                    isInviting = false
                    showInviteSuccess = true
                }
            } catch {
                print("Invite failed: \(error)")
                await MainActor.run { isInviting = false }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

