//
//  TodoItemViewModel.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import Foundation
import CoreData
import Combine


// MARK: - View Model Pattern
@MainActor
final class TodoItemViewModel: NSObject, ObservableObject {
    @Published var tasks: [TodoItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: CoreDataRepository<TodoItem>
    private var observationTask: Task<Void, Never>?
    
    init(repository: CoreDataRepository<TodoItem>) {
        self.repository = repository
        super.init()
        startObserving()
    }
    
    convenience override init() {
        self.init(repository: CoreDataRepository())
    }
    
    private func startObserving() {
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        
        isLoading = true
        
        observationTask = Task {
            for await tasks in repository.changesStream(sortDescriptors: [sortDescriptor]) {
                self.tasks = tasks
                self.isLoading = false
            }
        }
    }
    
    // MARK: - CRUD Operations
    func addTask(title: String, priority: Int = 0) async {
        errorMessage = nil
        let newTask = TodoItem(title: title, priority: priority)
        
        do {
            try await repository.create(newTask)
        } catch {
            errorMessage = "Failed to add task: \(error.localizedDescription)"
        }
    }
    
    func updateTask(_ task: TodoItem) async {
        errorMessage = nil
        do {
            try await repository.update(task)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func deleteTask(_ task: TodoItem) async {
        errorMessage = nil
        do {
            try await repository.delete(task)
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    func deleteTasks(_ tasks: [TodoItem]) async {
        errorMessage = nil
        do {
            try await repository.batchDelete(tasks)
        } catch {
            errorMessage = "Failed to delete tasks: \(error.localizedDescription)"
        }
    }
    
    func toggleTaskCompletion(_ task: TodoItem) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        await updateTask(updatedTask)
    }
    
    func deleteAllTasks() async {
        errorMessage = nil
        do {
            try await repository.deleteAll()
        } catch {
            errorMessage = "Failed to delete all tasks: \(error.localizedDescription)"
        }
    }
    
    deinit {
        observationTask?.cancel()
    }
}
