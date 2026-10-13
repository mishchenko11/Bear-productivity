import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @AppStorage("taskRemindersEnabled") private var taskRemindersEnabled = false
    @AppStorage("goalRemindersEnabled") private var goalRemindersEnabled = false
    @State private var showingNotificationPermissionAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("background").ignoresSafeArea()

                Form {
                    Section("Appearance") {
                        SettingsRow(title: "Theme", subtitle: "Light", symbol: "sun.max.fill")
                        SettingsRow(title: "App Icon", subtitle: "Default", symbol: "app.fill")
                    }

                    Section("Notifications") {
                        SettingsToggleRow(
                            title: "Reminders",
                            subtitle: "1 hour before timed tasks; 8:00 AM without a time",
                            symbol: "bell",
                            isOn: $taskRemindersEnabled
                        )
                        SettingsToggleRow(
                            title: "Goals",
                            subtitle: "A gentle reminder based on each goal's period",
                            symbol: "target",
                            isOn: $goalRemindersEnabled
                        )
                    }

                    Section("About") {
                        SettingsRow(title: "Version", subtitle: appVersion, symbol: "info.circle")
                        SettingsRow(
                            title: "Send Feedback",
                            subtitle: "Share your thoughts",
                            symbol: "bubble.left"
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(Color("brown"))
            .onChange(of: taskRemindersEnabled) { _, _ in
                Task {
                    await updateReminders()
                }
            }
            .onChange(of: goalRemindersEnabled) { _, _ in
                Task {
                    await updateReminders()
                }
            }
            .alert("Notifications aren't allowed", isPresented: $showingNotificationPermissionAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                }
                Button("Not Now", role: .cancel) { }
            } message: {
                Text("Allow notifications for Bears Up in iPhone Settings to receive task and goal reminders.")
            }
        }
    }

    @MainActor
    private func updateReminders() async {
        guard taskRemindersEnabled || goalRemindersEnabled else {
            await TaskReminderManager.refresh(
                in: modelContext,
                tasksEnabled: false,
                goalsEnabled: false
            )
            return
        }

        guard await TaskReminderManager.requestAuthorization() else {
            taskRemindersEnabled = false
            goalRemindersEnabled = false
            await TaskReminderManager.refresh(
                in: modelContext,
                tasksEnabled: false,
                goalsEnabled: false
            )
            showingNotificationPermissionAlert = true
            return
        }

        await TaskReminderManager.refresh(
            in: modelContext,
            tasksEnabled: taskRemindersEnabled,
            goalsEnabled: goalRemindersEnabled
        )
    }
}

private struct SettingsRow: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color("brown"))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Color("brown"))
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(Color("brown"))
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
