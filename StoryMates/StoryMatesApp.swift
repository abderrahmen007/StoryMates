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
            if authManager.isAuthenticated {
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            } else {
                LoginScreen()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            }
        }
    }
}
