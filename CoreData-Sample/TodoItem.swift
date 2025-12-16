//
//  TodoItem.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//


// MARK: - Example Domain Model
struct TodoItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var priority: Int
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), priority: Int = 0) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.priority = priority
    }
}