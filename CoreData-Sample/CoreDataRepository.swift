// MARK: - Core Data Repository Implementation
final class CoreDataRepository<DomainModel: ManagedObjectConvertible>: DataStoreProtocol, @unchecked Sendable where DomainModel.ManagedObject: NSManagedObject {
    typealias Entity = DomainModel
    
    private let coreDataStack: CoreDataStack
    private let context: NSManagedObjectContext
    
    init(coreDataStack: CoreDataStack = .shared, useBackgroundContext: Bool = false) {
        self.coreDataStack = coreDataStack
        self.context = useBackgroundContext ? coreDataStack.newBackgroundContext() : coreDataStack.viewContext
    }
    
    // MARK: - Create
    nonisolated func create(_ entity: Entity) async throws {
        try await context.perform { [weak self] in
            guard let self = self else { return }
            _ = entity.toManagedObject(in: self.context)
            try self.context.save()
        }
    }
    
    // MARK: - Fetch
    nonisolated func fetch(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) async throws -> [Entity] {
        // Wrap non-Sendable types for safe transfer across concurrency boundaries
        let sendablePredicate = await SendablePredicate(predicate)
        let sendableSortDescriptors = await SendableSortDescriptors(sortDescriptors)
        
        return try await context.perform { [weak self] in
            guard let self = self else { return [] }
            
            let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(entityName: String(describing: DomainModel.ManagedObject.self))
            fetchRequest.predicate = sendablePredicate.predicate
            fetchRequest.sortDescriptors = sendableSortDescriptors.sortDescriptors
            
            let managedObjects = try self.context.fetch(fetchRequest)
            return managedObjects.map { DomainModel.fromManagedObject($0) }
        }
    }
    
    // MARK: - Update
    nonisolated func update(_ entity: Entity) async throws {
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
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
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
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
    
    // MARK: - Delete All
    nonisolated func deleteAll() async throws {
        try await context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: DomainModel.ManagedObject.self))
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            let result = try self.context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
            }
        }
    }
    
    // MARK: - Save
    nonisolated func save() async throws {
        try await coreDataStack.save(context: context)
    }
    
    // MARK: - Helper Methods
    private func updateManagedObject(_ managedObject: DomainModel.ManagedObject, with entity: Entity) {
        // Convert entity to managed object to get updated values
        let tempContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        tempContext.parent = context
        let updatedManagedObject = entity.toManagedObject(in: tempContext)
        
        // Copy values from updated object to existing object
        let keys = Array(managedObject.entity.attributesByName.keys)
        let dict = updatedManagedObject.dictionaryWithValues(forKeys: keys)
        managedObject.setValuesForKeys(dict)
    }
}