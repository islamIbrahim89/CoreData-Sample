//
//  SendablePredicate.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import Foundation


// MARK: - Sendable Wrappers for Core Data Types
/// Sendable wrapper for NSPredicate
struct SendablePredicate: @unchecked Sendable {
    let predicate: NSPredicate?
    
    init(_ predicate: NSPredicate?) {
        self.predicate = predicate
    }
}
