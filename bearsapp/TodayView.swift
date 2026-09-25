//
//  TodayView.swift
//  bearsapp
//
//  Created by Irina on 17.09.26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDate = Date()
    @State private var showAddTask = false
    @Query private var tasks: [TaskItem]
    @State private var showDeleteAlert = false
    @State private var taskToDelete: TaskItem?
    @State private var taskToEdit: TaskItem?
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    private var todayTasks: [TaskItem] {
        tasks.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }.sorted {
            ($0.time ?? $0.date) < ($1.time ?? $1.date)
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
        
    }
    private var formattedDate: String {
        currentDate.formatted(
            .dateTime
                .weekday(.abbreviated)
                .month(.abbreviated)
                .day()
                .year()
        )
    }

    private var selectedDayName: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        }
        return selectedDate.formatted(.dateTime.weekday(.wide))
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(
            byAdding: .day,
            value: -daysFromMonday,
            to: selectedDate
        )!
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monday)
        }
    }
    
    var body: some View {
        List {
            Group {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(greeting)!")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    ForEach(weekDates, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(
                            day,
                            inSameDayAs: selectedDate
                        )
                        let isToday = Calendar.current.isDate(
                            day,
                            inSameDayAs: currentDate
                        )

                        Button {
                            selectedDate = day
                        } label: {
                            VStack(spacing: 8) {
                                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                Text(day.formatted(.dateTime.day()))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected
                                    ? (isToday
                                        ? Color("brown")
                                        : Color("brown").opacity(0.18))
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(
                                isSelected && isToday ? Color.white : Color("brown")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    Text(selectedDayName == "Today" ? "Today's Tasks" : "\(selectedDayName)'s Tasks")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color("brown"), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Task")
                }
                Group {
                    if todayTasks.isEmpty {
                        Text("No tasks for \(selectedDayName.lowercased()). Tap + to add one.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(todayTasks) { task in
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                taskToDelete = task
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)

                            Button {
                                taskToEdit = task
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color("brown"))
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.background))
        .alert("Are you sure you want to delete this task?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .destructive) {
                guard let task = taskToDelete else { return }
                withAnimation {
                    modelContext.delete(task)
                }
                taskToDelete = nil
            }
            Button("No", role: .cancel) {
                taskToDelete = nil
            }
        }
        .onAppear {
            currentDate = Date()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { currentDate = Date() }
        }
        .task {
            while !Task.isCancelled {
                currentDate = Date()
                do {
                    try await Task.sleep(for: .seconds(30))
                } catch {
                    return
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { showAddTask || taskToEdit != nil },
                set: { isPresented in
                    if !isPresented {
                        showAddTask = false
                        taskToEdit = nil
                    }
                }
            )
        ) {
            AddTaskView(taskToEdit: taskToEdit)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
