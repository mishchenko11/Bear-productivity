//
//  CalendarView.swift
//  bearsapp
//
//  Created by Irina on 17.09.26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @State private var selectedDate = Date()
    @Query private var tasks: [TaskItem]
    
    private var selectedDayTasks: [TaskItem] {
        tasks.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }.sorted {
            ($0.time ?? $0.date) < ($1.time ?? $1.date)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    displayedComponents: .date)
                .datePickerStyle(.graphical)
                Text(selectedDate, style: .date)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)

                if selectedDayTasks.isEmpty {
                    Text("No tasks for this day.")
                        .foregroundStyle(.secondary)
                }

                ForEach(selectedDayTasks) { task in
                    HStack() {
                        Button {
                            task.isCompleted.toggle()
                        } label: {
                            Image(systemName: task.isCompleted
                                  ? "checkmark.square.fill" : "square")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                task.isCompleted ? Color.white : Color("brown"),
                                Color("brown")
                            )
                            .font(.system(size: 26, weight: .regular))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(task.isCompleted ? "Mark incomplete: \(task.title)" : "Complete: \(task.title)")
                        .accessibilityValue(task.isCompleted ? "Completed" : "Incomplete")
                        Text(task.title)
                            .font(.headline)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? Color("brown") : Color.primary)
                        
                        Spacer()
                        
                        if let time = task.time {
                            Text(time, style: .time)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .tint(Color("brown"))
        .background(Color("background"))
    }
}
#Preview {
    CalendarView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
