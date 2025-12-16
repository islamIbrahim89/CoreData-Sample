//
//  CoreDataRepository.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import CoreData


// MARK: - Core Data Repository Implementation
final class CoreDataRepository<DomainModel: ManagedObjectConvertible>: DataStoreProtocol where DomainModel.ManagedObject: NSManagedObject {
    
    typealias Entity = DomainModel
    
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext
    
    init(coreDataStack: CoreDataStack = .shared, useBackgroundContext: Bool = false) {
        self.coreDataStack = coreDataStack
        // Store context - this is fine, contexts are thread-safe when used with perform blocks
        self.context = useBackgroundContext ? coreDataStack.newBackgroundContext() : coreDataStack.viewContext
    }
    
    // MARK: - Create
    nonisolated func create(_ entity: Entity) async throws {
        try await context.perform {
            _ = entity.toManagedObject(in: self.context)
            try self.context.save()
        }
    }
    
    // MARK: - Fetch
    nonisolated func fetch(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> [Entity] {
        // Wrap non-Sendable types for safe transfer across concurrency boundaries
        let sendablePredicate = await SendablePredicate(predicate)
        let sendableSortDescriptors = await SendableSortDescriptors(sortDescriptors)
        
        return try await context.perform {
            let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(entityName: String(describing: DomainModel.ManagedObject.self))
            fetchRequest.predicate = sendablePredicate.predicate
            fetchRequest.sortDescriptors = sendableSortDescriptors.sortDescriptors
            fetchRequest.fetchBatchSize = 20  // Improves performance for large datasets
            
            let managedObjects = try self.context.fetch(fetchRequest)
            return managedObjects.map { DomainModel.fromManagedObject($0) }
        }
    }
    
    // MARK: - Update
    nonisolated func update(_ entity: Entity) async throws {
        try await context.perform {
            // Fetch the existing object by ID
            let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(entityName: String(describing: DomainModel.ManagedObject.self))
            
            // Assuming the managed object has an 'id' property
            if let identifiable = entity as? any Identifiable,
               let id = identifiable.id as? UUID {
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                if let existingObject = try self.context.fetch(fetchRequest).first {
                    // Update the existing object
                    self.updateManagedObject(existingObject, with: entity)
                    try self.context.save()
                }
            }
        }
    }
    
    // MARK: - Delete
    nonisolated func delete(_ entity: Entity) async throws {
        try await context.perform {
            let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(entityName: String(describing: DomainModel.ManagedObject.self))
            
            if let identifiable = entity as? any Identifiable,
               let id = identifiable.id as? UUID {
                fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                fetchRequest.fetchLimit = 1
                
                if let objectToDelete = try self.context.fetch(fetchRequest).first {
                    self.context.delete(objectToDelete)
                    try self.context.save()
                }
            }
        }
    }
    
    // MARK: - Batch Delete (More efficient for multiple items)
    nonisolated func batchDelete(_ entities: [Entity]) async throws {
        guard !entities.isEmpty else { return }
        
        try await context.perform {
            let ids = entities.compactMap { ($0 as? any Identifiable)?.id as? UUID }
            guard !ids.isEmpty else { return }
            
            let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(entityName: String(describing: DomainModel.ManagedObject.self))
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            let objectsToDelete = try self.context.fetch(fetchRequest)
            for object in objectsToDelete {
                self.context.delete(object)
            }
            
            // ✅ Single save for all deletions
            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }
    
    // MARK: - Delete All
    /// ⚠️ WARNING: This uses NSBatchDeleteRequest which bypasses validation rules
    /// and relationship delete rules. If you have cascading deletes or complex
    /// business logic, consider using batchDelete() with fetched entities instead.
    nonisolated func deleteAll() async throws {
        try await context.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: DomainModel.ManagedObject.self))
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            let result = try self.context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                // Merge changes to both current context and viewContext to ensure UI updates
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes, 
                    into: [self.context, self.coreDataStack.viewContext]
                )
            }
            
            // ✅ Reset context to clear any cached objects and free memory
            self.context.reset()
        }
    }
    
    // MARK: - Save
    nonisolated func save() async throws {
        try await coreDataStack.save(context: context)
    }
    
    // MARK: - Helper Methods
    private func updateManagedObject(_ managedObject: DomainModel.ManagedObject, with entity: Entity) {
        // Use the protocol method for efficient updates
        entity.updateManagedObject(managedObject)
    }
}


// Add to CoreDataRepository
extension CoreDataRepository {
    func changesStream(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> AsyncStream<[Entity]> {
        AsyncStream { continuation in
            Task { @MainActor in
                let observer = CoreDataObserver<Entity>(
                    context: coreDataStack.viewContext,  // Correct: always use viewContext for observation
                    predicate: predicate,
                    sortDescriptors: sortDescriptors ?? []
                ) { updatedEntities in
                    continuation.yield(updatedEntities)
                }
                
                // Keep observer alive by capturing it strongly
                continuation.onTermination = { @Sendable [observer] _ in
                    // Observer will be deallocated when stream terminates
                    _ = observer
                }
            }
        }
    }
}
