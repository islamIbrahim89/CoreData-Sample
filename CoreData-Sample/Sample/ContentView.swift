//
//  ContentView.swift
//  CoreData-Sample
//
//  Created by islam moussa on 10/12/2025.
//
import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - Example SwiftUI View
struct TaskListView: View {
    @StateObject private var viewModel = TodoItemViewModel()
    
    @State private var newTaskTitle = ""
    
    var body: some View {
        Self._printChanges()
        
        return NavigationStack {
            VStack {
                // Add TodoItem Section
                HStack {
                    TextField("New task", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        Task {
                            await viewModel.addTask(title: newTaskTitle)
                            newTaskTitle = ""
                        }
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .padding()
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // TodoItem List
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    TaskList(viewModel: viewModel)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete All") {
                        Task {
                            await viewModel.deleteAllTasks()
                        }
                    }
                }
            }
        }
    }
}

struct TaskList: View {
    @ObservedObject var viewModel: TodoItemViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.tasks) { task in
                TaskRowView(task: task) {
                    Task {
                        await viewModel.toggleTaskCompletion(task)
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    let tasksToDelete = indexSet.map { viewModel.tasks[$0] }
                    await viewModel.deleteTasks(tasksToDelete)
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: TodoItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                
                Text(task.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if task.priority > 0 {
                Text("Priority: \(task.priority)")
                    .font(.caption)
                    .padding(4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
}
