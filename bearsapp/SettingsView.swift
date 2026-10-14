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

                ScrollView {
                    VStack(spacing: 20) {
                        SettingsGroupCard(title: "Appearance") {
                            VStack(spacing: 0) {
                                SettingsRow(title: "Theme", subtitle: "Light", symbol: "sun.max.fill")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)

                                settingsDivider

                                SettingsRow(title: "App Icon", subtitle: "Default", symbol: "app.fill")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                        }

                        SettingsGroupCard(title: "Notifications") {
                            VStack(spacing: 0) {
                                SettingsToggleRow(
                                    title: "Reminders",
                                    subtitle: "1 hour before timed tasks; 8:00 AM without a time",
                                    symbol: "bell",
                                    isOn: $taskRemindersEnabled
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)

                                settingsDivider

                                SettingsToggleRow(
                                    title: "Goals",
                                    subtitle: "A gentle reminder based on each goal's period",
                                    symbol: "target",
                                    isOn: $goalRemindersEnabled
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }

                        SettingsGroupCard(title: "About") {
                            VStack(spacing: 0) {
                                SettingsRow(title: "Version", subtitle: appVersion, symbol: "info.circle")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)

                                settingsDivider

                                SettingsRow(
                                    title: "Send Feedback",
                                    subtitle: "Share your thoughts",
                                    symbol: "bubble.left"
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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

    private var settingsDivider: some View {
        Divider()
            .padding(.leading, 60)
            .padding(.trailing, 16)
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

private struct SettingsGroupCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("brown").opacity(0.18), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
