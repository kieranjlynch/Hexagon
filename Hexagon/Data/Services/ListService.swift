//
//  ListService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import CoreData
import UIKit
import Combine
import os

public protocol TaskLimitChecking {
    func canAddTaskWithStartDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool
    func canAddTaskWithEndDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool
}

public protocol ListServiceProtocol: BaseProvider where T == TaskList {
    func fetchAllLists() async throws -> [TaskList]
    func fetchRecentLists(limit: Int) async throws -> [TaskList]
    func fetchInboxList() async throws -> TaskList
    func deleteTaskList(_ taskList: TaskList) async throws
    func saveTaskList(name: String, color: UIColor, symbol: String) async throws -> TaskList
    func updateTaskList(_ taskList: TaskList, name: String, color: UIColor, symbol: String) async throws
    func initialize() async
}

@MainActor
public class ListService: ObservableObject, TaskLimitChecking, ListServiceProtocol {
    public static let shared = ListService()
    public let persistentContainer: NSPersistentContainer
    @Published public private(set) var taskLists: [TaskList] = []
    private let logger = Logger(subsystem: "com.hexagon", category: "ListService")
    private var isInitialized = false
    private let userDefaults = UserDefaults.standard
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    public func initialize() async {
        if isInitialized { return }
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                persistentContainer.viewContext.perform {
                    do {
                        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
                        request.sortDescriptors = [
                            NSSortDescriptor(keyPath: \TaskList.order, ascending: true),
                            NSSortDescriptor(keyPath: \TaskList.createdAt, ascending: true)
                        ]
                        self.taskLists = try request.execute()
                        self.isInitialized = true
                        continuation.resume()
                    } catch {
                        self.logger.error("Failed to initialize ListService: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            logger.error("Failed to initialize ListService: \(error.localizedDescription)")
        }
    }
    
    public func ensureInboxListExists() async throws {
        _ = try await fetchInboxList()
    }
    
    public func canAddTaskWithStartDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool {
        let isStartLimitUnlimited = userDefaults.bool(forKey: "isStartLimitUnlimited")
        if isStartLimitUnlimited {
            return true
        }
        let maxTasksStartedPerDay = userDefaults.integer(forKey: "maxTasksStartedPerDay")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate >= %@ AND startDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) } ?? NSPredicate(value: true)
        ])
        
        let count = try await context.perform {
            try context.count(for: fetchRequest)
        }
        return count < maxTasksStartedPerDay
    }
    
    
    public func canAddTaskWithEndDate(_ date: Date, excluding reminderID: UUID?) async throws -> Bool {
        let isCompletionLimitUnlimited = userDefaults.bool(forKey: "isCompletionLimitUnlimited")
        if isCompletionLimitUnlimited {
            return true
        }
        
        let maxTasksCompletedPerDay = userDefaults.integer(forKey: "maxTasksCompletedPerDay")
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "endDate >= %@ AND endDate < %@", startOfDay as NSDate, endOfDay as NSDate),
            reminderID.map { NSPredicate(format: "reminderID != %@", $0 as CVarArg) } ?? NSPredicate(value: true)
        ])
        
        let count = try await context.perform {
            try context.count(for: fetchRequest)
        }
        
        return count < maxTasksCompletedPerDay
    }
    
    
    public func updateTaskLists() async throws -> [TaskList] {
        let context = persistentContainer.viewContext
        
        return try await context.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskList.order, ascending: true),
                NSSortDescriptor(keyPath: \TaskList.createdAt, ascending: true)
            ]
            let fetchedLists = try context.fetch(request)
            self.taskLists = fetchedLists
            return fetchedLists
        }
    }
    
    public func fetchRecentLists(limit: Int) async throws -> [TaskList] {
        let context = PersistenceController.shared.persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.fetchLimit = limit
        request.predicate = NSPredicate(format: "name != nil AND name != ''")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.createdAt, ascending: false)]
        let results = try await context.perform {
            try context.fetch(request)
        }
        results.forEach { list in
        }
        return results
    }
    
    public func fetchInboxList() async throws -> TaskList {
        let context = persistentContainer.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", "Inbox")
            request.fetchLimit = 1
            
            if let existingInbox = try context.fetch(request).first {
                try context.save()
                return existingInbox
            }
            
            let inbox = TaskList(context: context)
            inbox.listID = UUID()
            inbox.name = "Inbox"
            inbox.order = 0
            inbox.createdAt = Date()
            inbox.symbol = "tray"
            
            try context.save()
            
            return inbox
        }
    }
    
    public func deleteTaskList(_ taskList: TaskList) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    guard let taskListInContext = try context.existingObject(with: taskList.objectID) as? TaskList else {
                        continuation.resume()
                        return
                    }

                    let reminders = taskListInContext.reminders?.allObjects as? [Reminder] ?? []
                    for reminder in reminders {
                        context.delete(reminder)
                    }
                    
                    let subHeadings = taskListInContext.subHeadings?.allObjects as? [SubHeading] ?? []
                    for subHeading in subHeadings {
                        context.delete(subHeading)
                    }
                    
                    context.delete(taskListInContext)
                    try context.save()

                    Task { @MainActor in
                        if let index = self.taskLists.firstIndex(where: { $0.objectID == taskList.objectID }) {
                            self.taskLists.remove(at: index)
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func saveTaskList(name: String, color: UIColor, symbol: String) async throws -> TaskList {
        guard !name.isEmpty else { throw ListServiceError.invalidName }
        
        let context = persistentContainer.viewContext
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TaskList, Error>) in
            context.perform {
                do {
                    let taskList = TaskList(context: context)
                    taskList.listID = UUID()
                    taskList.name = name
                    taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
                    taskList.symbol = symbol
                    taskList.createdAt = Date()
                    taskList.order = Int16(self.taskLists.count)
                    
                    try context.save()
                    self.taskLists.append(taskList)
                    continuation.resume(returning: taskList)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func updateTaskList(_ taskList: TaskList, name: String, color: UIColor, symbol: String) async throws {
        guard !name.isEmpty else { throw ListServiceError.invalidName }
        
        let context = persistentContainer.viewContext
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    taskList.name = name
                    taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
                    taskList.symbol = symbol
                    try context.save()
                    
                    if let index = self.taskLists.firstIndex(where: { $0.objectID == taskList.objectID }) {
                        self.taskLists[index] = taskList
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func mergeDuplicateLists() async throws {
        let context = persistentContainer.newBackgroundContext()
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
                    let allLists = try context.fetch(request)
                    let listsByName = Dictionary(grouping: allLists, by: { $0.name ?? "" })
                    
                    for (_, lists) in listsByName where lists.count > 1 {
                        let sortedLists = lists.sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
                        guard let mainList = sortedLists.first else { continue }
                        
                        for duplicateList in sortedLists.dropFirst() {
                            duplicateList.reminders?.forEach { ($0 as? Reminder)?.list = mainList }
                            duplicateList.subHeadings?.forEach { ($0 as? SubHeading)?.taskList = mainList }
                            context.delete(duplicateList)
                        }
                    }
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func fetchAllLists() async throws -> [TaskList] {
        let context = persistentContainer.viewContext
        
        return try await context.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskList.order, ascending: true),
                NSSortDescriptor(keyPath: \TaskList.createdAt, ascending: true)
            ]
            return try context.fetch(request)
        }
    }
}

extension ListService {
    public enum ListServiceError: LocalizedError {
        case invalidName
        case saveFailed(Error)
        
        public var errorDescription: String? {
            switch self {
            case .invalidName:
                return "List name cannot be empty"
            case .saveFailed(let error):
                return "Failed to save list: \(error.localizedDescription)"
            }
        }
    }
}

extension ListService: BaseProvider {
    public func fetch() async throws -> [TaskList] {
        return try await fetchAllLists()
    }
    
    public func fetchOne(id: UUID) async throws -> TaskList? {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.predicate = NSPredicate(format: "listID == %@", id as CVarArg)
        return try await context.perform {
            try request.execute().first
        }
    }
    
    public func save(_ item: TaskList) async throws {
        try await updateTaskList(item, name: item.name ?? "", color: item.color ?? .systemBlue, symbol: item.symbol ?? "list.bullet")
    }
    
    public func delete(_ item: TaskList) async throws {
        try await deleteTaskList(item)
    }
}

extension TaskList {
    var color: UIColor? {
        get {
            guard let colorData = self.colorData else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        }
        set {
            if let newValue = newValue {
                self.colorData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
            } else {
                self.colorData = nil
            }
        }
    }
}

