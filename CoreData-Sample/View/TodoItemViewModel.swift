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
    
    var errorMessage: String?
    
    private var fetchedResultsController: NSFetchedResultsController<TaskEntity>
    private let repository: CoreDataRepository<TodoItem>
    
    init(repository: CoreDataRepository<TodoItem>) {
        self.repository = repository
        
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        fetchRequest.fetchBatchSize = 20
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: CoreDataStack.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: "TodoItemCache"
        )
        
        super.init()
        fetchedResultsController.delegate = self
        performInitialFetch()
    }
    
    convenience override init() {
        self.init(repository: CoreDataRepository())
    }
    
    private func performInitialFetch() {
        do {
            try fetchedResultsController.performFetch()
            Task {
                await loadTasks()
            }
        } catch {
            errorMessage = "Failed to fetch: \(error.localizedDescription)"
            objectWillChange.send()
        }
    }
    
    // MARK: - CRUD Operations
    func loadTasks() async {
        //isLoading = true
        errorMessage = nil
        
        do {
            let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
            tasks = try await repository.fetch(sortDescriptors: [sortDescriptor])
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
        }
        
        //isLoading = false
    }
    
    func addTask(title: String, priority: Int = 0) async {
        let newTask = TodoItem(title: title, priority: priority)
        
        do {
            try await repository.create(newTask)
        } catch {
            errorMessage = "Failed to add task: \(error.localizedDescription)"
        }
    }
    
    func updateTask(_ task: TodoItem) async {
        do {
            try await repository.update(task)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func deleteTask(_ task: TodoItem) async {
        do {
            try await repository.delete(task)
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    func toggleTaskCompletion(_ task: TodoItem) async {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        await updateTask(updatedTask)
    }
    
    func deleteAllTasks() async {
        do {
            try await repository.deleteAll()
        } catch {
            errorMessage = "Failed to delete all tasks: \(error.localizedDescription)"
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TodoItemViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Called after Core Data changes
        Task {
            await loadTasks()
            // UI automatically updates via @Published tasks! ✨
        }
    }
}
