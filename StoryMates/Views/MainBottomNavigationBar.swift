import SwiftUI



// MARK: - MainTabView (SwiftUI TabView, tap-to-show nav bar)
struct MainTabView: View {
    @State private var selectedTab: MainTab = .chat
    @State private var showTabBar: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView(userId: "123e4567-e89b-12d3-a456-426614174000")
                .tabItem {
                    Label("CHAT", systemImage: "message.fill")
                }
            HomeView()
                .tabItem {
                    Label("HOME", systemImage: "house.fill")
                }
                .tag(MainTab.home)

                .tag(MainTab.chat)
        }
        .toolbar(showTabBar ? .visible : .hidden, for: .tabBar)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showTabBar.toggle()
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarHidden(true)
        .onChange(of: selectedTab) { _ in
            // Hide nav bar after tab switch
            withAnimation(.easeInOut(duration: 0.2)) {
                showTabBar = false
            }
        }
    }
}

enum MainTab: String, CaseIterable {
    case chat = "chat"
    case home = "home"

}

// MARK: - Previews

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
