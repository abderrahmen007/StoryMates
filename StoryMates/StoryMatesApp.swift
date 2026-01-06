//
//  StoryMatesApp.swift
//  StoryMates
//
//  Created by mac on 11/10/25.
//

import SwiftUI
import CoreData

@main
struct StoryMatesApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                } else {
                    if authManager.isAuthenticated {
                        MainTabView()
                            .onAppear {
                                if let userId = authManager.userId {
                                    WebSocketService.shared.connect(userId: userId)
                                }
                            }
                    } else {
                        LoginScreen()
                    }
                }
            }
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(themeManager)
            .environmentObject(authManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
}
