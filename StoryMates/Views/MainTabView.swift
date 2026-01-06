import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    @ObservedObject private var authManager = AuthManager.shared
    
    init() {
        // Customize Tab Bar appearance with pixelated theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "PressStart2P-Regular", size: 8) ?? UIFont.systemFont(ofSize: 8)
        ]
        
        // Unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray,
            .font: UIFont(name: "PressStart2P-Regular", size: 8) ?? UIFont.systemFont(ofSize: 8)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    @State private var showingNotification = false
    @State private var notificationMessage = ""
    @State private var notificationType = ""
    
    // For invite popup
    @State private var pendingNotification: [String: Any]? = nil
    @State private var showInvitePopup = false
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                NavigationView {
                    HomeView()
                }
                .navigationViewStyle(.stack)
                .environmentObject(themeManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                

                NavigationView {
                    ChatView(userId: authManager.userId ?? "default_user")
                }
                .navigationViewStyle(.stack)
                .environmentObject(themeManager)
                .tabItem {
                    Label("AI Chat", systemImage: "message.fill")
                }
                
                NavigationView {
                    TeammateFinderView()
                }
                .navigationViewStyle(.stack)
                .environmentObject(themeManager)
                .tabItem {
                    Label("Find", systemImage: "person.2.fill")
                }
                
                NavigationView {
                    CommunityView()
                }
                .navigationViewStyle(.stack)
                .environmentObject(themeManager)
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }
                
                NavigationView {
                    ProfileView()
                }
                .navigationViewStyle(.stack)
                .environmentObject(themeManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            }
            .accentColor(.white)
            
            // Notification Banner - CLICKABLE
            if showingNotification {
                VStack {
                    HStack {
                        Image(systemName: getNotificationIcon())
                            .foregroundColor(.black)
                        VStack(alignment: .leading) {
                            Text(getNotificationTitle())
                                .font(.custom("PressStart2P-Regular", size: 12))
                                .foregroundColor(.black)
                            Text(notificationMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                        }
                        Spacer()
                        if notificationType == "GAME_INVITE" {
                            Text("Tap →")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(getNotificationColor())
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                    .onTapGesture {
                        if notificationType == "GAME_INVITE" && pendingNotification != nil {
                            showInvitePopup = true
                            withAnimation { showingNotification = false }
                        } else {
                            withAnimation { showingNotification = false }
                        }
                    }
                }
                .transition(.move(edge: .top))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showInvitePopup) {
            if let notification = pendingNotification {
                InviteResponseSheet(notification: notification) {
                    pendingNotification = nil
                }
            }
        }
        .onReceive(WebSocketService.shared.notificationSubject) { notification in
            if let type = notification["type"] as? String {
                self.notificationType = type
                
                if type == "GAME_INVITE" {
                    if let fromUser = notification["fromUser"] as? [String: Any],
                       let name = fromUser["name"] as? String {
                        self.notificationMessage = "\(name) invited you to play!"
                        self.pendingNotification = notification
                    }
                } else if type == "INVITE_ACCEPTED" {
                    if let fromUser = notification["fromUser"] as? [String: Any],
                       let name = fromUser["name"] as? String {
                        self.notificationMessage = "\(name) accepted your invite! 🎉"
                    }
                } else {
                    self.notificationMessage = "You have a new notification"
                }
                
                withAnimation {
                    self.showingNotification = true
                }
                
                // Auto hide after 6 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation {
                        self.showingNotification = false
                    }
                }
            }
        }
    }
    
    private func getNotificationIcon() -> String {
        switch notificationType {
        case "GAME_INVITE": return "envelope.fill"
        case "INVITE_ACCEPTED": return "checkmark.circle.fill"
        default: return "bell.fill"
        }
    }
    
    private func getNotificationTitle() -> String {
        switch notificationType {
        case "GAME_INVITE": return "Game Invite!"
        case "INVITE_ACCEPTED": return "Invite Accepted!"
        default: return "Notification"
        }
    }
    
    private func getNotificationColor() -> Color {
        switch notificationType {
        case "INVITE_ACCEPTED": return Color.blue
        default: return Color.green
        }
    }
}

// MARK: - Invite Response Sheet
struct InviteResponseSheet: View {
    let notification: [String: Any]
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isLoading = false
    @State private var showMatchSuccess = false
    @State private var senderName = ""
    @State private var senderId = ""
    
    private let networkManager = NetworkManager()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                if showMatchSuccess {
                    matchSuccessView
                } else {
                    profileView
                }
            }
            .padding(24)
        }
        .onAppear {
            extractSenderInfo()
        }
    }
    
    private var profileView: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(String(senderName.prefix(2)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .accentColor(.white)
            
            // Notification Banner - CLICKABLE
            if showingNotification {
                VStack {
                    HStack {
                        Image(systemName: getNotificationIcon())
                            .foregroundColor(.black)
                        VStack(alignment: .leading) {
                            Text(getNotificationTitle())
                                .font(.custom("PressStart2P-Regular", size: 12))
                                .foregroundColor(.black)
                            Text(notificationMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                        }
                        Spacer()
                        if notificationType == "GAME_INVITE" {
                            Text("Tap →")
                                .font(.system(size: 12))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(getNotificationColor())
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                    .onTapGesture {
                        if notificationType == "GAME_INVITE" && pendingNotification != nil {
                            showInvitePopup = true
                            withAnimation { showingNotification = false }
                        } else {
                            withAnimation { showingNotification = false }
                        }
                    }
                }
                .transition(.move(edge: .top))
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showInvitePopup) {
            if let notification = pendingNotification {
                InviteResponseSheet(notification: notification) {
                    pendingNotification = nil
                }
            }
        }
        .onReceive(WebSocketService.shared.notificationSubject) { notification in
            if let type = notification["type"] as? String {
                self.notificationType = type
                
                if type == "GAME_INVITE" {
                    if let fromUser = notification["fromUser"] as? [String: Any],
                       let name = fromUser["name"] as? String {
                        self.notificationMessage = "\(name) invited you to play!"
                        self.pendingNotification = notification
                    }
                } else if type == "INVITE_ACCEPTED" {
                    if let fromUser = notification["fromUser"] as? [String: Any],
                       let name = fromUser["name"] as? String {
                        self.notificationMessage = "\(name) accepted your invite! 🎉"
                    }
                } else {
                    self.notificationMessage = "You have a new notification"
                }
                
                withAnimation {
                    self.showingNotification = true
                }
                
                // Auto hide after 6 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation {
                        self.showingNotification = false
                    }
                }
            }
        }
    }
    
    private func getNotificationIcon() -> String {
        switch notificationType {
        case "GAME_INVITE": return "envelope.fill"
        case "INVITE_ACCEPTED": return "checkmark.circle.fill"
        default: return "bell.fill"
        }
    }
    
    private func getNotificationTitle() -> String {
        switch notificationType {
        case "GAME_INVITE": return "Game Invite!"
        case "INVITE_ACCEPTED": return "Invite Accepted!"
        default: return "Notification"
        }
    }
    
    private func getNotificationColor() -> Color {
        switch notificationType {
        case "INVITE_ACCEPTED": return Color.blue
        default: return Color.green
        }
    }
}

// MARK: - Invite Response Sheet
struct InviteResponseSheet: View {
    let notification: [String: Any]
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isLoading = false
    @State private var showMatchSuccess = false
    @State private var senderName = ""
    @State private var senderId = ""
    
    private let networkManager = NetworkManager()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.18)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                if showMatchSuccess {
                    matchSuccessView
                } else {
                    profileView
                }
            }
            .padding(24)
        }
        .onAppear {
            extractSenderInfo()
        }
    }
    
    private var profileView: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.purple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(String(senderName.prefix(2)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name
            Text(senderName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("wants to play with you!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer().frame(height: 20)
            
            // Buttons
            HStack(spacing: 16) {
                // Decline
                Button(action: declineInvite) {
                    Text("Decline")
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .disabled(isLoading)
                
                // Accept
                Button(action: acceptInvite) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Accept")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .disabled(isLoading)
            }
        }
    }
    
    private var matchSuccessView: some View {
        VStack(spacing: 20) {
            Text("🎮")
                .font(.system(size: 60))
            
            Text("It's a Match!")
                .font(.custom("PressStart2P-Regular", size: 20))
                .foregroundColor(.yellow)
            
            Text("You and \(senderName) can now message each other!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 20)
            
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                Text("💬 Start Chatting")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                Text("Maybe Later")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func extractSenderInfo() {
        if let fromUser = notification["fromUser"] as? [String: Any] {
            senderName = fromUser["name"] as? String ?? "Unknown"
            senderId = fromUser["_id"] as? String ?? ""
        }
    }
    
    private func acceptInvite() {
        guard let myId = authManager.userId else { return }
        isLoading = true
        
        Task {
            do {
                let result = try await networkManager.respondToInvite(
                    swiperId: myId,
                    targetId: senderId,
                    action: "like"
                )
                
                await MainActor.run {
                    isLoading = false
                    if result.match {
                        showMatchSuccess = true
                    } else {
                        // Accepted but not a mutual match yet
                        dismiss()
                        onDismiss()
                    }
                }
            } catch {
                print("❌ Failed to accept invite: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func declineInvite() {
        guard let myId = authManager.userId else { return }
        isLoading = true
        
        Task {
            do {
                _ = try await networkManager.respondToInvite(
                    swiperId: myId,
                    targetId: senderId,
                    action: "pass"
                )
            } catch {
                print("❌ Failed to decline invite: \(error)")
            }
            
            await MainActor.run {
                dismiss()
                onDismiss()
            NavigationView {
                MyCollectionView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Collection", systemImage: "square.grid.2x2.fill")
            }
            
            NavigationView {
                ProjectsMainScreen()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Projects", systemImage: "folder.fill")
            }
            
            NavigationView {
                ChatView(userId: authManager.userId ?? "default_user")
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("AI Chat", systemImage: "message.fill")
            }
            
            NavigationView {
                ImageAnalysisView(onBack: {})
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Analysis", systemImage: "photo.badge.checkmark.fill")
            }
            
            NavigationView {
                CommunityHubView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Community", systemImage: "person.3.fill")
            }
            
            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
    }
}
