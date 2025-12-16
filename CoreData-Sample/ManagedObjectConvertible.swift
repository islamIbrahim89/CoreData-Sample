// MARK: - Model Protocol
/// Protocol that domain models should conform to
protocol ManagedObjectConvertible {
    associatedtype ManagedObject: NSManagedObject
    
    /// Convert domain model to Core Data managed object
    func toManagedObject(in context: NSManagedObjectContext) -> ManagedObject
    
    /// Create domain model from Core Data managed object
    static func fromManagedObject(_ managedObject: ManagedObject) -> Self
}