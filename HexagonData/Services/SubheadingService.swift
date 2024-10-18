//
//  SubheadingService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 18/09/2024.
//

import Foundation
import CoreData
import Combine

@MainActor
public class SubheadingService: ObservableObject {
    private let persistentContainer: NSPersistentContainer
    
    @Published public private(set) var subHeadings: [SubHeading] = []
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }

    public func saveSubHeading(title: String, taskList: TaskList) async throws -> SubHeading {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        return try await context.perform {
            let taskListInContext = context.object(with: taskList.objectID) as! TaskList
            
            let subHeading = SubHeading(context: context)
            subHeading.subheadingID = UUID()
            subHeading.title = title
            subHeading.order = Int16(taskListInContext.subHeadings?.count ?? 0)
            subHeading.taskList = taskListInContext
            taskListInContext.addToSubHeadings(subHeading)
            
            try context.save()
            return subHeading
        }
    }

    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        let context = persistentContainer.viewContext
        let taskListInContext = context.object(with: taskList.objectID) as! TaskList
        
        let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
        request.predicate = NSPredicate(format: "taskList == %@", taskListInContext)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SubHeading.order, ascending: true)]
        
        return try await context.perform { [weak self] in
            let results = try context.fetch(request)
            self?.subHeadings = results
            return results
        }
    }
   
    public func fetchSubHeadingsCount(for taskList: TaskList) async throws -> Int {
        let context = persistentContainer.viewContext
        let taskListInContext = context.object(with: taskList.objectID) as! TaskList
        
        return try await context.perform {
            let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
            request.predicate = NSPredicate(format: "taskList == %@", taskListInContext)
            return try context.count(for: request)
        }
    }
  
    public func updateSubHeading(_ subHeading: SubHeading, title: String) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
            subHeadingInContext.title = title
            try context.save()
        }
    }

    public func deleteSubHeading(_ subHeading: SubHeading) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
            context.delete(subHeadingInContext)
            try context.save()
        }
    }

    public func reorderSubHeadings(_ subHeadings: [SubHeading]) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            for (index, subHeading) in subHeadings.enumerated() {
                let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
                subHeadingInContext.order = Int16(index)
            }
            try context.save()
        }
    }

    public func moveReminder(_ reminder: Reminder, to subHeading: SubHeading?) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            let reminderInContext = context.object(with: reminder.objectID) as! Reminder
            if let subHeading = subHeading {
                let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
                reminderInContext.subHeading = subHeadingInContext
            } else {
                reminderInContext.subHeading = nil
            }
            try context.save()
        }
    }
}
