//
//  TaskEntity.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import CoreData


// MARK: - Core Data Entity (Example)
/// This would be your Core Data entity class
/// In real implementation, this is generated from .xcdatamodeld file
///
@objc(TaskEntity)
public class TaskEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var priority: Int16
}

extension TaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }
}

// MARK: - Domain Model to Core Data Conversion
extension TodoItem: ManagedObjectConvertible {
    typealias ManagedObject = TaskEntity
    
    func toManagedObject(in context: NSManagedObjectContext) -> TaskEntity {
        let entity = TaskEntity(context: context)
        entity.id = self.id
        entity.title = self.title
        entity.isCompleted = self.isCompleted
        entity.createdAt = self.createdAt
        entity.priority = Int16(self.priority)
        return entity
    }
    
    static func fromManagedObject(_ managedObject: TaskEntity) -> TodoItem {
        return TodoItem(
            id: managedObject.id,
            title: managedObject.title,
            isCompleted: managedObject.isCompleted,
            createdAt: managedObject.createdAt,
            priority: Int(managedObject.priority)
        )
    }
    
    func updateManagedObject(_ managedObject: TaskEntity) {
        // Only update mutable properties
        managedObject.title = self.title
        managedObject.isCompleted = self.isCompleted
        managedObject.priority = Int16(self.priority)
        // Don't update id and createdAt - they should be immutable
    }
}
