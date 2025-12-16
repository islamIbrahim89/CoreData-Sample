//
//  DataStoreProtocol.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import Foundation


// MARK: - Data Store Protocol
/// Protocol defining CRUD operations - can be implemented by Core Data or SwiftData
protocol DataStoreProtocol: Sendable {
    associatedtype Entity
    
    func create(_ entity: Entity) async throws
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) async throws -> [Entity]
    func update(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func deleteAll() async throws
    func save() async throws
}
