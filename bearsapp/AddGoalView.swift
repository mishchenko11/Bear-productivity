import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("taskRemindersEnabled") private var taskRemindersEnabled = false
    @AppStorage("goalRemindersEnabled") private var goalRemindersEnabled = false
    @State private var title: String
    @State private var targetCount: Int
    @State private var period: String
    @State private var showingSaveError = false

    private let goalToEdit: GoalItem?
    private let periods = ["day", "week", "month", "year"]

    private var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(goalToEdit: GoalItem? = nil) {
        self.goalToEdit = goalToEdit
        _title = State(initialValue: goalToEdit?.title ?? "")
        _targetCount = State(initialValue: goalToEdit?.targetCount ?? 2)
        _period = State(initialValue: goalToEdit?.period ?? "month")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("What do you want to achieve?", text: $title)

                Stepper("Target: \(targetCount)", value: $targetCount, in: 1...100)

                Picker("Period", selection: $period) {
                    ForEach(periods, id: \.self) { item in
                        Text(item.capitalized).tag(item)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("background"))
            .navigationTitle(goalToEdit == nil ? "Add Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveGoal)
                        .disabled(isTitleEmpty)
                }
            }
            .tint(Color("brown"))
            .alert("Couldn't save goal", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your goal hasn't been saved. Please try again.")
            }
        }
    }

    private func saveGoal() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let goal: GoalItem
        if let goalToEdit {
            goal = goalToEdit
            goal.title = trimmedTitle
            goal.targetCount = targetCount
            goal.period = period
        } else {
            let goalColors = ["green", "orange", "purple"]
            let randomColor = goalColors.randomElement() ?? "orange"
            goal = GoalItem(
                title: trimmedTitle,
                targetCount: targetCount,
                period: period,
                colorName: randomColor
            )
            modelContext.insert(goal)
        }

        do {
            try modelContext.save()
            Task {
                await TaskReminderManager.refresh(
                    in: modelContext,
                    tasksEnabled: taskRemindersEnabled,
                    goalsEnabled: goalRemindersEnabled
                )
                dismiss()
            }
        } catch {
            showingSaveError = true
        }
    }
}

#Preview {
    AddGoalView()
        .modelContainer(for: GoalItem.self, inMemory: true)
}
