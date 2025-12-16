//
//  ManagedObjectConvertible.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import CoreData


// MARK: - Model Protocol
/// Protocol that domain models should conform to
protocol ManagedObjectConvertible {
    associatedtype ManagedObject: NSManagedObject
    
    /// Convert domain model to Core Data managed object
    func toManagedObject(in context: NSManagedObjectContext) -> ManagedObject
    
    /// Create domain model from Core Data managed object
    static func fromManagedObject(_ managedObject: ManagedObject) -> Self
    
    /// Update an existing managed object with values from this domain model
    /// This is more efficient than creating a new object
    func updateManagedObject(_ managedObject: ManagedObject)
}
