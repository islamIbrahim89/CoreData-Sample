//
//  CoreData_SampleApp.swift
//  CoreData-Sample
//
//  Created by islam moussa on 10/12/2025.
//

import SwiftUI

@main
struct CoreData_SampleApp: App {
    
    init() {
        let _ = DependencyInjection.shared
    }
    var body: some Scene {
        WindowGroup {
            let vm = DependencyInjection.shared.resolve(TodoItemViewModel.self)
            TaskListView(viewModel: vm)
        }
    }
}

import Swinject

final class ViewModelAssembly: Assembly {
    func assemble(container: Container) {
        // UserListViewModel - Transient
        container.register(TodoItemViewModel.self) { resolver in
            TodoItemViewModel(
                repository: resolver.resolve(CoreDataRepository<TodoItem>.self)!
            )
        }
        
        container.register(CoreDataRepository<TodoItem>.self) { _ in
            CoreDataRepository<TodoItem>()
        }
    }
}


// MARK: - DI/DependencyInjection.swift

import Swinject

final class DependencyInjection {
    static let shared = DependencyInjection()
    
    let container: Container
    private let assembler: Assembler
    
    private init() {
        container = Container()
        
        assembler = Assembler(
            [
                ViewModelAssembly()
            ],
            container: container
        )
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let resolved = container.resolve(type) else {
            fatalError("Failed to resolve \(type)")
        }
        return resolved
    }
    
    // For testing purposes
    func reset() {
        container.removeAll()
    }
}


@propertyWrapper
struct Injected<T> {
    private let service: T
    
    init() {
        self.service = DependencyInjection.shared.resolve(T.self)
    }
    
    public var wrappedValue: T {
        get { service }
    }
}
