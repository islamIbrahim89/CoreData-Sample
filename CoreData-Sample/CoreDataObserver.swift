// MARK: - Core Data Observer Service
@MainActor
final class CoreDataObserver<DomainModel: ManagedObjectConvertible>: NSObject where DomainModel.ManagedObject: NSManagedObject {
    
    private let fetchedResultsController: NSFetchedResultsController<DomainModel.ManagedObject>
    private let onUpdate: ([DomainModel]) -> Void
    
    init(
        context: NSManagedObjectContext,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor],
        onUpdate: @escaping ([DomainModel]) -> Void
    ) {
        self.onUpdate = onUpdate
        
        let fetchRequest = NSFetchRequest<DomainModel.ManagedObject>(
            entityName: String(describing: DomainModel.ManagedObject.self)
        )
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = 20
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil // Use nil for dynamic predicates
        )
        
        super.init()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            notifyChanges()
        } catch {
            print("Failed to perform initial fetch: \(error)")
        }
    }
    
    private func notifyChanges() {
        guard let objects = fetchedResultsController.fetchedObjects else {
            onUpdate([])
            return
        }
        
        let domainModels = objects.map { DomainModel.fromManagedObject($0) }
        onUpdate(domainModels)
    }
}

extension CoreDataObserver: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        notifyChanges()
    }
}