// MARK: - Sendable Wrappers for Core Data Types
/// Sendable wrapper for NSPredicate
struct SendablePredicate: @unchecked Sendable {
    let predicate: NSPredicate?
    
    init(_ predicate: NSPredicate?) {
        self.predicate = predicate
    }
}

/// Sendable wrapper for NSSortDescriptor array
struct SendableSortDescriptors: @unchecked Sendable {
    let sortDescriptors: [NSSortDescriptor]?
    
    init(_ sortDescriptors: [NSSortDescriptor]?) {
        self.sortDescriptors = sortDescriptors
    }
}
