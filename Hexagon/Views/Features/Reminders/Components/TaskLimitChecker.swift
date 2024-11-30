//
//  TaskLimitChecker.swift
//  Hexagon
//
//  Created by Kieran Lynch on 27/11/2024.
//

import Foundation
import CoreData
import SwiftUI


class TaskLimitChecker: TaskLimitChecking {
    private let context: NSManagedObjectContext
    @AppStorage("maxTasksStartedPerDay") private var maxTasksStartedPerDay: Int = 3
    @AppStorage("maxTasksCompletedPerDay") private var maxTasksCompletedPerDay: Int = 5
    @AppStorage("isStartLimitUnlimited") private var isStartLimitUnlimited: Bool = true
    @AppStorage("isCompletionLimitUnlimited") private var isCompletionLimitUnlimited: Bool = true
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func canAddTaskWithStartDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool {
        if isStartLimitUnlimited {
            return true
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate >= %@ AND startDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) } ?? NSPredicate(value: true)
        ])
        
        let count = try await context.perform {
            try self.context.count(for: fetchRequest)
        }
        
        return count < self.maxTasksStartedPerDay
    }
    
    func canAddTaskWithEndDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool {
        if isCompletionLimitUnlimited {
            return true
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "endDate >= %@ AND endDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) } ?? NSPredicate(value: true)
        ])
        
        let count = try await context.perform {
            try self.context.count(for: fetchRequest)
        }
        
        return count < self.maxTasksCompletedPerDay
    }
}
