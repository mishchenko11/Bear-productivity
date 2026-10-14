//
//  bearsApp.swift
//  bearsapp
//
//  Created by Irina on 17.09.26.
//

import SwiftUI
import SwiftData

@main
struct shibaApp: App {
    @AppStorage("hasCompletedWelcome")
    private var hasCompletedWelcome = false
    @AppStorage("taskRemindersEnabled")
    private var taskRemindersEnabled = false
    @AppStorage("goalRemindersEnabled")
    private var goalRemindersEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            TaskCompletion.self,
            GoalItem.self,
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
                    .task {
                        await refreshReminders()
                    }
                    .onChange(of: scenePhase) { _, phase in
                        guard phase == .active else { return }
                        Task {
                            await refreshReminders()
                        }
                    }
            } else {
                WelcomeView {
                    hasCompletedWelcome = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func refreshReminders() async {
        await TaskReminderManager.refresh(
            in: sharedModelContainer.mainContext,
            tasksEnabled: taskRemindersEnabled,
            goalsEnabled: goalRemindersEnabled
        )
    }
}
