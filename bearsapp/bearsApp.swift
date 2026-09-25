//
//  bearsApp.swift
//  bearsapp
//
//  Created by Irina on 17.09.26.
//

import SwiftUI
import SwiftData

@main
struct bearsApp: App {
    @AppStorage("hasCompletedWelcome")
    private var hasCompletedWelcome = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedWelcome {
                ContentView()
            } else {
                WelcomeView {
                    hasCompletedWelcome = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
