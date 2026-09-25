//
//  AddTaskView.swift
//  bearsapp
//
//  Created by Irina on 18.09.26.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var time = Date()
    @State private var includeTime = false
    @State private var showingSaveError = false
    private let taskToEdit: TaskItem?

    private var isTitleEmpty: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(taskToEdit: TaskItem? = nil) {
        self.taskToEdit = taskToEdit
        
        _title = State(initialValue: taskToEdit?.title ?? "")
        _date = State(initialValue: taskToEdit?.date ?? Date())
        _time = State(initialValue: taskToEdit?.time ?? Date())
        _includeTime = State(initialValue: taskToEdit?.time != nil)
    }
    
    var body: some View {
        NavigationStack {
          Form {
            TextField("Task title", text: $title)
            
            DatePicker(
                "Date",
                selection: $date,
                displayedComponents: .date)
            
            Toggle("Add time", isOn: $includeTime)

            if includeTime {
              DatePicker(
                "Time",
                selection: $time,
                displayedComponents: .hourAndMinute)
            }

          }
          .scrollContentBackground(.hidden)
          .safeAreaInset(edge: .bottom) {
              Button(action: saveTask) {
                  Text(taskToEdit == nil ? "Save Task" : "Save Changes")
                      .font(.system(size: 18, weight: .semibold, design: .rounded))
                      .foregroundStyle(.white)
                      .frame(maxWidth: .infinity)
                      .frame(minHeight: 54)
                      .background(Color("brown"), in: Capsule())
              }
              .buttonStyle(.plain)
              .disabled(isTitleEmpty)
              .opacity(isTitleEmpty ? 0.5 : 1)
              .padding(.horizontal, 32)
              .padding(.top, 12)
              .padding(.bottom, 20)
              .background(Color("background"))
          }
          .background(Color("background"))
          .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
          .navigationBarTitleDisplayMode(.inline)
          .tint(Color("brown"))
          .alert("Couldn't save task", isPresented: $showingSaveError) {
              Button("OK", role: .cancel) { }
          } message: {
              Text("Your task hasn't been saved. Please try again.")
          }
        }
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let scheduledTime = includeTime ? calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: day
        ) : nil
        let task: TaskItem
        if let taskToEdit {
            task = taskToEdit
            task.title = trimmedTitle
            task.date = day
            task.time = scheduledTime
        } else {
            task = TaskItem(title: trimmedTitle, date: day, time: scheduledTime)
            modelContext.insert(task)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            showingSaveError = true
        }
    }
}

#Preview {
    AddTaskView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
