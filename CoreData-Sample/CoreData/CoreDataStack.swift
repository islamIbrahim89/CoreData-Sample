//
//  CoreDataStack.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import CoreData


// MARK: - Core Data Stack
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let persistentContainer: NSPersistentContainer
    private(set) var loadError: Error?
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "AppModel")
        
        // ✅ Configure persistent store for better performance
        if let storeDescription = persistentContainer.persistentStoreDescriptions.first {
            // Enable persistent history tracking for better multi-context coordination
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications for real-time updates
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Use write-ahead logging for better performance
            storeDescription.setOption("WAL" as NSString, forKey: "journal_mode")
        }
        
        // Configure for better performance
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // ✅ Disable undo manager for better performance (unless you need undo functionality)
        persistentContainer.viewContext.undoManager = nil
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                // ✅ Store error instead of crashing immediately
                self.loadError = error
                
                // In development, crash to catch issues early
                #if DEBUG
                fatalError("Unable to load persistent stores: \(error)")
                #else
                // In production, log error and attempt recovery
                print("⚠️ Core Data load error: \(error)")
                // You could attempt to delete and recreate the store here
                #endif
            }
        }
    }
    
    /// Create a background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil  // ✅ Disable undo for better performance
        return context
    }
    
    /// Save context with error handling
    func save(context: NSManagedObjectContext) async throws {
        guard context.hasChanges else { return }
        
        try await context.perform {
            try context.save()
        }
    }
}
