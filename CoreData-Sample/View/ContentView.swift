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
            .task {
                await viewModel.loadTasks()
            }
        }
    }
}

struct TaskList: View {
    @StateObject var viewModel: TodoItemViewModel
    
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
                    for index in indexSet {
                        await viewModel.deleteTask(viewModel.tasks[index])
                    }
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

// MARK: - Migration Path to SwiftData
/*
 When ready to migrate to SwiftData, follow these steps:
 
 1. Create SwiftData models:
 
    @Model
    final class TodoItemModel {
        @Attribute(.unique) var id: UUID
        var title: String
        var isCompleted: Bool
        var createdAt: Date
        var priority: Int
        
        init(id: UUID = UUID(), title: String, isCompleted: Bool = false,
             createdAt: Date = Date(), priority: Int = 0) {
            self.id = id
            self.title = title
            self.isCompleted = isCompleted
            self.createdAt = createdAt
            self.priority = priority
        }
    }
 
 2. Implement SwiftData Repository:
 
    final class SwiftDataRepository<DomainModel>: DataStoreProtocol {
        typealias Entity = DomainModel
        
        private let modelContainer: ModelContainer
        private let modelContext: ModelContext
        
        init(modelContainer: ModelContainer) {
            self.modelContainer = modelContainer
            self.modelContext = ModelContext(modelContainer)
        }
        
        // Implement CRUD operations using SwiftData APIs
    }
 
 3. Update Domain Model conformance:
 
    extension TodoItem {
        func toSwiftDataModel() -> TodoItemModel {
            TodoItemModel(id: id, title: title, isCompleted: isCompleted,
                     createdAt: createdAt, priority: priority)
        }
        
        static func fromSwiftDataModel(_ model: TodoItemModel) -> TodoItem {
            TodoItem(id: model.id, title: model.title, isCompleted: model.isCompleted,
                 createdAt: model.createdAt, priority: model.priority)
        }
    }
 
 4. Swap repository in ViewModel:
    // Change from CoreDataRepository to SwiftDataRepository
    init(repository: SwiftDataRepository<TodoItem> = SwiftDataRepository()) {
        self.repository = repository
    }
 
 5. The rest of your code remains unchanged!
 */

