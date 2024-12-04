//
//  ReminderFetchingService.swift
//  Hexagon
//
//  Created by Kieran Lynch on [date].
//

import Foundation
import CoreData
import os
import Combine

public protocol ListDataProvider {
    func deleteTaskList(_ taskList: TaskList) async throws
    func fetchTaskLists() async throws -> [TaskList]
    func getIncompleteRemindersCount(for taskList: TaskList) async -> Int
    func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading]
}

public protocol TimelineDataProvider {
    func fetchTasks(from: Date, filter: TimelineFilter) async throws -> [Reminder]
    func fetchTaskLists() async throws -> [TaskList]
}

public protocol TodayTaskFetching {
    func fetchTasks() async throws -> [Reminder]
    func isTaskOverdue(_ task: Reminder) -> Bool
}

public protocol SearchDataProvider: Actor {
    func fetchInitialResults() async throws -> [Reminder]
    func performSearch(text: String, tokens: [ReminderToken], basePredicate: (any Sendable)?) async throws -> [Reminder]
}

public protocol CompletedTasksFetching {
    func fetchCompletedTasks() async throws -> [Reminder]
    func uncompleteTask(_ reminder: Reminder) async throws
}

public protocol ReminderServiceFacade {
    func fetchReminders(for list: TaskList, isCompleted: Bool) async throws -> [Reminder]
    func fetchSortedReminders(for list: TaskList, sortType: ReminderSortType) async throws -> [Reminder]
    func toggleCompletion(_ reminder: Reminder) async throws -> Reminder
    func existingObject<T: NSManagedObject>(with objectID: NSManagedObjectID, as type: T.Type) async -> T?
    func fetchReminder(withID id: UUID) async throws -> Reminder?
}

@preconcurrency import CoreData

public actor ReminderFetchingService: ListDataProvider, TimelineDataProvider, TodayTaskFetching, SearchDataProvider, CompletedTasksFetching, ReminderServiceFacade {
    
    private let modificationService: ReminderModificationService
    
    @MainActor
    public static let shared = {
        let service = ReminderFetchingService(
            persistenceController: PersistenceController.shared,
            modificationService: ReminderModificationService.shared
        )
        return service
    }()
    
    public let persistentContainer: NSPersistentContainer
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "ReminderFetchingService")
    
    public init(persistenceController: PersistenceController, modificationService: ReminderModificationService) {
        self.persistentContainer = persistenceController.persistentContainer
        self.modificationService = modificationService
    }
    
    public func existingObject<T: NSManagedObject>(
        with objectID: NSManagedObjectID,
        as type: T.Type
    ) async -> T? {
        let context = persistentContainer.viewContext
        return await context.perform {
            try? context.existingObject(with: objectID) as? T
        }
    }
    
    public func fetchReminder(withID id: UUID) async throws -> Reminder? {
        let predicateRep = PredicateRepresentation(
            format: "reminderID == %@",
            arguments: [id]
        )
        
        let reminders = try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            fetchLimit: 1
        )
        return reminders.first
    }
    
    public func fetchTodayTasks() async throws -> [Reminder] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let predicateRep = PredicateRepresentation(
            format: "startDate >= %@ AND startDate < %@ AND isCompleted == NO",
            arguments: [startOfToday as NSDate, endOfToday as NSDate]
        )
        
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "priority", ascending: false)
        ]
        
        let tasks = try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
        return tasks
    }
    
    public func fetchTasks() async throws -> [Reminder] {
        let predicateRep = PredicateRepresentation(format: "isCompleted == NO", arguments: [])
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "priority", ascending: false)
        ]
        let tasks = try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
        return tasks
    }
    
    
    public func fetchReminders(for list: TaskList, isCompleted: Bool) async throws -> [Reminder] {
        if list.objectID.isTemporaryID {
            try await list.managedObjectContext?.perform {
                try list.managedObjectContext?.obtainPermanentIDs(for: [list])
            }
        }
        
        let predicateRep = PredicateRepresentation(
            format: "list == %@ AND isCompleted == %@",
            arguments: [list, NSNumber(value: isCompleted)]
        )
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "priority", ascending: false)
        ]
        
        return try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
    }
    
    public func fetchSortedReminders(for list: TaskList, sortType: ReminderSortType) async throws -> [Reminder] {
        if list.objectID.isTemporaryID {
            try await list.managedObjectContext?.perform {
                try list.managedObjectContext?.obtainPermanentIDs(for: [list])
            }
        }
        
        let predicateRep = PredicateRepresentation(
            format: "list == %@",
            arguments: [list]
        )
        
        let sortDescriptors = [sortType.sortDescriptorRepresentation]
        
        return try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
    }
    
    public func toggleCompletion(_ reminder: Reminder) async throws -> Reminder {
        guard let context = reminder.managedObjectContext else {
            throw NSError(
                domain: "ReminderFetchingService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No context found for reminder"]
            )
        }
        
        try await context.perform {
            reminder.isCompleted.toggle()
            reminder.completedAt = reminder.isCompleted ? Date() : nil
            try context.save()
        }
        
        return reminder
    }
    
    public func fetchTaskLists() async throws -> [TaskList] {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let request = NSFetchRequest<TaskList>(entityName: "TaskList")
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let lists = try context.fetch(request)
            return lists
        }
    }
    
    public func deleteTaskList(_ taskList: TaskList) async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            context.delete(taskList)
            try context.save()
        }
    }
    
    public func fetchInitialResults() async throws -> [Reminder] {
        let predicateRep = PredicateRepresentation(format: "isCompleted == NO", arguments: [])
        let sortDescriptors = [SortDescriptorRepresentation(key: "startDate", ascending: true)]
        
        let results = try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
        return results
    }
    
    public func performSearch(
        text: String,
        tokens: [ReminderToken],
        basePredicate: (any Sendable)?
    ) async throws -> [Reminder] {
        var predicateFormat = ""
        var predicateArguments: [Any] = []
        
        if !text.isEmpty {
            predicateFormat += "(title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@)"
            predicateArguments.append(text)
            predicateArguments.append(text)
        }
        
        for token in tokens {
            if !predicateFormat.isEmpty {
                predicateFormat += " AND "
            }
            
            switch token {
            case .priority(let value):
                predicateFormat += "priority == %@"
                predicateArguments.append(value)
            case .tag(let id, _):
                predicateFormat += "ANY tags.tagID == %@"
                predicateArguments.append(id)
            }
        }
        
        if predicateFormat.isEmpty {
            return []
        }
        
        let predicateRep = PredicateRepresentation(
            format: predicateFormat,
            arguments: predicateArguments
        )
        
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "priority", ascending: false)
        ]
        
        return try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
    }
    
    nonisolated public func isTaskOverdue(_ task: Reminder) -> Bool {
        guard let startDate = task.startDate else { return false }
        return startDate < Date() && !task.isCompleted
    }
    
    public func fetchTasks(from date: Date, filter: TimelineFilter) async throws -> [Reminder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        var format = "startDate >= %@ AND startDate < %@"
        var arguments: [Any] = [startOfDay as NSDate, endOfDay as NSDate]
        
        switch filter {
        case .inbox:
            format += " AND list == nil"
        case .specificList(let list):
            format += " AND list == %@"
            arguments.append(list)
        case .all:
            break
        }
        
        let predicateRep = PredicateRepresentation(format: format, arguments: arguments)
        let sortDescriptors = [
            SortDescriptorRepresentation(key: "startDate", ascending: true),
            SortDescriptorRepresentation(key: "priority", ascending: false)
        ]
        
        return try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
    }
    
    public func fetchCompletedTasks() async throws -> [Reminder] {
        let predicateRep = PredicateRepresentation(
            format: "isCompleted == %@ AND completedAt != nil",
            arguments: [NSNumber(value: true)]
        )
        let sortDescriptors = [SortDescriptorRepresentation(key: "completedAt", ascending: false)]
        let tasks = try await executeFetchRequest(
            entity: Reminder.self,
            predicateRepresentation: predicateRep,
            sortDescriptorRepresentations: sortDescriptors
        )
        return tasks
    }
    
    public func uncompleteTask(_ reminder: Reminder) async throws {
        let context = persistentContainer.newBackgroundContext()
        let objectID = reminder.objectID
        
        try await context.perform {
            guard let reminderInContext = try? context.existingObject(with: objectID) as? Reminder else {
                throw NSError(
                    domain: "com.hexagon",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Reminder not found"]
                )
            }
            
            reminderInContext.isCompleted = false
            reminderInContext.completedAt = nil
            
            try context.save()
        }
    }
    
    public func getIncompleteRemindersCount(for taskList: TaskList) async -> Int {
        let context = persistentContainer.viewContext
        return await context.perform {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = NSPredicate(format: "list == %@ AND isCompleted == NO", taskList)
            let count = (try? context.count(for: request)) ?? 0
            return count
        }
    }
    
    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let request: NSFetchRequest<SubHeading> = SubHeading.fetchRequest()
            request.predicate = NSPredicate(format: "taskList == %@", taskList)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \SubHeading.order, ascending: true)]
            let subheadings = try context.fetch(request)
            return subheadings
        }
    }
    
    public func executeFetchRequest<T: NSManagedObject>(
        entity: T.Type,
        predicateRepresentation: PredicateRepresentation?,
        sortDescriptorRepresentations: [SortDescriptorRepresentation] = [],
        fetchLimit: Int? = nil
    ) async throws -> [T] {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let request = NSFetchRequest<T>(entityName: String(describing: T.self))
            
            if let predicateRep = predicateRepresentation,
               !predicateRep.format.isEmpty {
                request.predicate = NSPredicate(
                    format: predicateRep.format,
                    argumentArray: predicateRep.arguments
                )
            }
            
            request.sortDescriptors = sortDescriptorRepresentations.map { $0.toNSSortDescriptor() }
            
            if let limit = fetchLimit {
                request.fetchLimit = limit
            }
            
            let results = try context.fetch(request)
            return results
        }
    }
}
