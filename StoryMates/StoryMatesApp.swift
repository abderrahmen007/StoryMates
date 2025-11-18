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

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
