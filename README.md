# Core Data Sample Project

A modern, production-ready example of Core Data implementation in Swift using clean architecture principles, Swift Concurrency, and SwiftUI.

## 📋 Overview

This project demonstrates best practices for implementing Core Data in a Swift application with:

- **Clean Architecture**: Separation of concerns with domain models, repository pattern, and protocols
- **Swift Concurrency**: Full async/await support with proper Sendable conformance
- **Type Safety**: Protocol-oriented design with generic repositories
- **Real-time Updates**: NSFetchedResultsController integration with AsyncStream
- **Performance Optimizations**: Batch operations, WAL mode, and efficient context management

## 🏗️ Architecture

### Project Structure

```
CoreData-Sample/
├── Domain Layer
│   ├── TodoItem.swift                    # Domain model (Identifiable, Equatable, Sendable)
│   └── DataStoreProtocol.swift          # Abstract data store interface
│
├── Data Layer
│   ├── ManagedObjectConvertible.swift   # Protocol for model ↔ entity conversion
│   ├── TaskEntity.swift                 # Core Data entity definition
│   ├── CoreDataStack.swift              # Persistent container & context management
│   ├── CoreDataRepository.swift         # Generic repository implementation
│   ├── CoreDataObserver.swift           # NSFetchedResultsController wrapper
│   └── SendablePredicate.swift          # Sendable wrappers for Core Data types
│
└── Presentation Layer
    ├── TodoItemViewModel.swift          # @MainActor view model
    └── ContentView.swift                # SwiftUI views
```

### Architecture Layers

#### 1. **Domain Layer**
The domain layer contains pure Swift models and interfaces:

- **`TodoItem`**: A simple Swift struct representing a task
  - Conforms to `Identifiable`, `Equatable`, and `Sendable`
  - No Core Data dependencies
  - Can be easily tested and reused

- **`DataStoreProtocol`**: Abstract interface for data persistence
  - Defines CRUD operations
  - Can be implemented by Core Data, SwiftData, or any other storage solution
  - Enables dependency injection and testing

#### 2. **Data Layer**
The data layer handles Core Data integration:

- **`ManagedObjectConvertible`**: Protocol for converting between domain models and Core Data entities
  - `toManagedObject()`: Creates new managed objects
  - `fromManagedObject()`: Converts managed objects to domain models
  - `updateManagedObject()`: Efficiently updates existing entities

- **`CoreDataStack`**: Manages the Core Data stack
  - Singleton pattern for app-wide access
  - Configures persistent store with optimizations (WAL mode, history tracking)
  - Provides both main and background contexts

- **`CoreDataRepository<T>`**: Generic repository implementing `DataStoreProtocol`
  - Type-safe CRUD operations
  - Async/await API
  - Batch operations for performance
  - Uses `context.perform()` for thread safety

- **`CoreDataObserver`**: Wraps `NSFetchedResultsController` for reactive updates
  - Converts Core Data notifications to AsyncStream
  - Automatically converts entities to domain models
  - Maintains strong reference for lifecycle management

#### 3. **Presentation Layer**
The presentation layer uses SwiftUI and MVVM:

- **`TodoItemViewModel`**: `@MainActor` view model
  - Manages UI state with `@Published` properties
  - Coordinates between view and repository
  - Observes data changes via AsyncStream
  - Handles errors gracefully

- **`TaskListView`**: Main SwiftUI interface
  - Add, toggle, and delete tasks
  - Real-time updates when data changes
  - Loading and error states

## 🚀 Key Features

### 1. **Clean Separation of Concerns**
```swift
// Domain model - no Core Data dependency
struct TodoItem: Identifiable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}

// Core Data entity - separate from domain
@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
}
```

### 2. **Generic Repository Pattern**
```swift
// Works with any domain model that conforms to ManagedObjectConvertible
let todoRepository = CoreDataRepository<TodoItem>()
let userRepository = CoreDataRepository<User>()

// Type-safe operations
try await todoRepository.create(myTodoItem)
let allTodos = try await todoRepository.fetch()
```

### 3. **Swift Concurrency Integration**
```swift
// All operations are async and thread-safe
@MainActor
func addTask() async {
    let task = TodoItem(title: "Learn Core Data")
    try await repository.create(task)  // Runs on background context
}
```

### 4. **Real-time Data Updates**
```swift
// Subscribe to changes with AsyncStream
for await tasks in repository.changesStream() {
    self.tasks = tasks  // UI updates automatically
}
```

### 5. **Performance Optimizations**

- **WAL Mode**: Write-ahead logging for better concurrent performance
- **Batch Operations**: Efficient multi-item deletions
- **Fetch Batch Size**: Pagination support for large datasets
- **Context Management**: Separate contexts for UI and background work
- **No Undo Manager**: Disabled for better performance (re-enable if needed)

## 📱 Usage Examples

### Creating Tasks
```swift
let task = TodoItem(title: "Buy groceries", priority: 2)
try await repository.create(task)
```

### Fetching Tasks
```swift
// Fetch all
let allTasks = try await repository.fetch()

// Fetch with predicate
let completedPredicate = NSPredicate(format: "isCompleted == YES")
let completedTasks = try await repository.fetch(predicate: completedPredicate)

// Fetch with sorting
let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
let sortedTasks = try await repository.fetch(sortDescriptors: [sortDescriptor])
```

### Updating Tasks
```swift
var task = myTask
task.isCompleted = true
try await repository.update(task)
```

### Deleting Tasks
```swift
// Delete single task
try await repository.delete(task)

// Batch delete
try await repository.batchDelete([task1, task2, task3])

// Delete all
try await repository.deleteAll()
```

### Observing Changes
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var tasks: [TodoItem] = []
    
    func startObserving() {
        Task {
            for await tasks in repository.changesStream() {
                self.tasks = tasks
            }
        }
    }
}
```

## ⚙️ Core Data Stack Configuration

The project uses an optimized Core Data stack:

```swift
// Persistent history tracking for multi-context coordination
storeDescription.setOption(true, forKey: NSPersistentHistoryTrackingKey)

// Remote change notifications for real-time updates
storeDescription.setOption(true, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// Write-ahead logging for better performance
storeDescription.setOption("WAL", forKey: "journal_mode")

// Automatic merge from parent contexts
viewContext.automaticallyMergesChangesFromParent = true
```

## 🧪 Testing

The architecture enables easy testing:

```swift
// Mock repository for testing
class MockRepository: DataStoreProtocol {
    var tasks: [TodoItem] = []
    
    func create(_ entity: TodoItem) async throws {
        tasks.append(entity)
    }
    
    func fetch(predicate: NSPredicate? = nil, 
               sortDescriptors: [NSSortDescriptor]? = nil) async throws -> [TodoItem] {
        return tasks
    }
}

// Inject mock into view model
let viewModel = TodoItemViewModel(repository: MockRepository())
```

## 🔧 Setup Requirements

### Prerequisites
- iOS 16.0+ / macOS 13.0+
- Xcode 15.0+
- Swift 5.9+

### Core Data Model Setup

1. Create an `.xcdatamodeld` file named `AppModel.xcdatamodeld`
2. Add an entity named `TaskEntity` with the following attributes:
   - `id`: UUID
   - `title`: String
   - `isCompleted`: Boolean
   - `createdAt`: Date
   - `priority`: Integer 16

## 📊 Best Practices Demonstrated

### ✅ Thread Safety
- All Core Data operations use `context.perform()` blocks
- Sendable wrappers for non-Sendable Core Data types
- `@MainActor` isolation for view models

### ✅ Memory Management
- Undo managers disabled for better performance
- Context reset after batch operations
- Proper cleanup in `deinit`

### ✅ Error Handling
- Errors propagated through async throws
- User-friendly error messages in UI
- Development vs. production error handling

### ✅ Performance
- Batch operations for multiple items
- Fetch batch size for pagination
- Background contexts for heavy operations
- NSBatchDeleteRequest for efficient deletions

### ✅ Maintainability
- Protocol-oriented design
- Generic implementations
- Clear separation of concerns
- Well-documented code

## 🎯 When to Use This Architecture

**Use this approach when:**
- Building production apps with Core Data
- Need to support multiple data sources (Core Data, SwiftData, API)
- Want to write testable code
- Require real-time data synchronization
- Working with complex domain models

**Consider alternatives when:**
- Building a simple prototype → Use SwiftData directly
- Only storing simple settings → Use UserDefaults
- Need cross-platform support → Consider SQLite or Realm

## 🔄 Migration Path

### From SwiftData
SwiftData can implement the same `DataStoreProtocol`:

```swift
final class SwiftDataRepository<T>: DataStoreProtocol {
    func create(_ entity: T) async throws { /* SwiftData code */ }
    // ... implement other methods
}
```

### From Existing Core Data Code
1. Extract domain models from managed objects
2. Implement `ManagedObjectConvertible` for each model
3. Replace direct Core Data calls with repository methods
4. Migrate views to use view models

## 📚 Additional Resources

- [Apple Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

## 👤 Author

Created by Islam Moussa on December 15, 2025

## 📄 License

This is a sample project for educational purposes. Feel free to use and modify as needed.

---

## 💡 Key Takeaways

1. **Separate domain models from Core Data entities** for better testability and flexibility
2. **Use protocols and generics** to create reusable, type-safe repository code
3. **Embrace Swift Concurrency** with async/await instead of completion handlers
4. **Leverage NSFetchedResultsController** with AsyncStream for reactive data flow
5. **Optimize Core Data** with proper configuration (WAL, batch operations, context management)
6. **Keep views simple** by moving business logic to view models
7. **Make code Sendable-safe** for proper Swift 6 concurrency support

This architecture scales from small apps to large production codebases while maintaining clean, testable, and performant code.

