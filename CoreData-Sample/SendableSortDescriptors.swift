/// Sendable wrapper for NSSortDescriptor array
struct SendableSortDescriptors: @unchecked Sendable {
    let sortDescriptors: [NSSortDescriptor]?
    
    init(_ sortDescriptors: [NSSortDescriptor]?) {
        self.sortDescriptors = sortDescriptors
    }
}