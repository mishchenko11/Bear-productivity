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
    
    private var todayTasks: [TaskItem] {
        tasks.filter {
            Calendar.current.isDate($0.date, inSameDayAs: currentDate)
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
                
                HStack {
                    Text("Today's Tasks")
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
                        Text("No tasks for today. Tap + to add one.")
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
                        }
                        Button {
                            taskToEdit = task
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color("brown"))
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
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}
