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

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                        .onAppear {
                            // Ensure SocketIO connects when main view appears
                            SocketIOManager.shared.connectChat()
                            SocketIOManager.shared.connectNotifications()
                            if let userId = authManager.userId {
                                SocketIOManager.shared.listenForCalls(userId: userId)
                            }
                        }
                    
                    CallOverlayView() // Global Call Overlay
                } else {
                    LoginScreen()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                }
            }
        }
    }
}
