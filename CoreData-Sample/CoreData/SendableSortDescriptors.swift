//
//  SendableSortDescriptors.swift
//  CoreData-Sample
//
//  Created by islam moussa on 15/12/2025.
//

import Foundation


/// Sendable wrapper for NSSortDescriptor array
struct SendableSortDescriptors: @unchecked Sendable {
    let sortDescriptors: [NSSortDescriptor]?
    
    init(_ sortDescriptors: [NSSortDescriptor]?) {
        self.sortDescriptors = sortDescriptors
    }
}
