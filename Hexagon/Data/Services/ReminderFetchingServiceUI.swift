//
//  ReminderFetchingServiceUI.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/11/2024.
//

import Foundation
import CoreData
import os
import Combine

@MainActor
public protocol ReminderFetching {
    var context: NSManagedObjectContext { get }
    func getReminder(withID objectID: NSManagedObjectID) throws -> Reminder
    func fetchReminders(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> Result<[Reminder], Error>
    func fetchTimelineTasks(with filter: ListFilter, fromDate: Date, predicates: [String], arguments: [Any]) -> Result<[Reminder], Error>
}

@MainActor
public final class ReminderFetchingServiceUI: NSObject, ObservableObject, ReminderFetching {
    public let service: ReminderFetchingService
    public let context: NSManagedObjectContext
    
    @Published public private(set) var reminders: [Reminder] = []

    public static let shared = ReminderFetchingServiceUI()

    public override init() {
        self.service = ReminderFetchingService.shared
        self.context = service.persistentContainer.viewContext
        super.init()
    }

    public init(service: ReminderFetchingService) {
        self.service = service
        self.context = service.persistentContainer.viewContext
        super.init()
    }

    public func getReminder(withID objectID: NSManagedObjectID) throws -> Reminder {
        try context.existingObject(with: objectID) as! Reminder
    }

    public func fetchReminders(
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor]?
    ) -> Result<[Reminder], Error> {
        do {
            let request = Reminder.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            let fetchedReminders = try context.fetch(request)
            return .success(fetchedReminders)
        } catch {
            return .failure(error)
        }
    }

    public func fetchTimelineTasks(
        with filter: ListFilter,
        fromDate: Date,
        predicates: [String],
        arguments: [Any]
    ) -> Result<[Reminder], Error> {
        do {
            let request = Reminder.fetchRequest()
            
            var finalPredicates = predicates
            let finalArguments = arguments
            
            switch filter {
            case .active:
                finalPredicates.append("isCompleted == NO")
            case .completed:
                finalPredicates.append("isCompleted == YES")
            case .all:
                break
            }
            
            let predicateFormat = finalPredicates.joined(separator: " AND ")
            request.predicate = NSPredicate(format: predicateFormat, argumentArray: finalArguments)
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            
            let reminders = try context.fetch(request)
            return .success(reminders)
        } catch {
            return .failure(error)
        }
    }

    public func existingObject<T: NSManagedObject>(
        with objectID: NSManagedObjectID,
        as type: T.Type
    ) async -> T? {
        try? context.existingObject(with: objectID) as? T
    }

    public func fetchTasks() async throws -> [Reminder] {
        try await service.fetchTasks()
    }

    public func uncompleteTask(_ reminder: Reminder) async throws {
        try await service.uncompleteTask(reminder)
    }

    public func deleteTaskList(_ taskList: TaskList) async throws {
        try await service.deleteTaskList(taskList)
    }

    public func getIncompleteRemindersCount(for taskList: TaskList) async -> Int {
        await service.getIncompleteRemindersCount(for: taskList)
    }

    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        try await service.fetchSubHeadings(for: taskList)
    }

    public func fetchTasks(from date: Date, filter: TimelineFilter) async throws -> [Reminder] {
        try await service.fetchTasks(from: date, filter: filter)
    }

    public func fetchTaskLists() async throws -> [TaskList] {
        try await service.fetchTaskLists()
    }

    public func isTaskOverdue(_ task: Reminder) async -> Bool {
        service.isTaskOverdue(task)
    }

    public func fetchCompletedTasks() async throws -> [Reminder] {
        try await service.fetchCompletedTasks()
    }

    public func fetchInitialResults() async throws -> [Reminder] {
        try await service.fetchInitialResults()
    }

    public func performSearch(
        text: String,
        tokens: [ReminderToken],
        basePredicate: (any Sendable)?
    ) async throws -> [Reminder] {
        try await service.performSearch(
            text: text,
            tokens: tokens,
            basePredicate: basePredicate
        )
    }
}
