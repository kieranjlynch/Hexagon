//
//  TaskLimitManager.swift
//  Hexagon
//
//  Created by Kieran Lynch on 06/11/2024.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class TaskLimitManager {
    static let shared = TaskLimitManager()
    
    @AppStorage("maxTasksStartedPerDay") private var maxTasksStartedPerDay: Int = 3
    @AppStorage("maxTasksCompletedPerDay") private var maxTasksCompletedPerDay: Int = 5
    @AppStorage("isStartLimitUnlimited") private var isStartLimitUnlimited: Bool = true
    @AppStorage("isCompletionLimitUnlimited") private var isCompletionLimitUnlimited: Bool = true
    
    private let persistentContainer: NSPersistentContainer
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistentContainer = persistenceController.persistentContainer
        
        UserDefaults.standard.register(defaults: [
            "maxTasksStartedPerDay": 3,
            "maxTasksCompletedPerDay": 5,
            "isStartLimitUnlimited": true,
            "isCompletionLimitUnlimited": true
        ])
    }
    
    func canAddTaskWithStartDate(_ date: Date, excluding reminderID: UUID? = nil) async throws -> Bool {
        guard !isStartLimitUnlimited else { return true }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicates = [
            NSPredicate(format: "startDate >= %@ AND startDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            NSPredicate(format: "isCompleted = false"),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) }
        ].compactMap { $0 }
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let context = persistentContainer.viewContext
        let count = try await context.perform {
            try context.count(for: fetchRequest)
        }
        
        return count < maxTasksStartedPerDay
    }
    
    func canAddTaskWithEndDate(_ date: Date, excluding reminderID: UUID? = nil) async throws -> Bool {
        guard !isCompletionLimitUnlimited else { return true }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicates = [
            NSPredicate(format: "endDate >= %@ AND endDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            NSPredicate(format: "isCompleted = false"),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) }
        ].compactMap { $0 }
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let context = persistentContainer.viewContext
        let count = try await context.perform {
            try context.count(for: fetchRequest)
        }
        
        return count < maxTasksCompletedPerDay
    }
}
