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
import WidgetKit

@MainActor
public class ListService: ObservableObject {
    public static let shared = ListService()

    public let persistentContainer: NSPersistentContainer

    @Published public private(set) var taskLists: [TaskList] = []

    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }

    public enum ListServiceError: Error, LocalizedError {
        case duplicateListName
        public var errorDescription: String? {
            switch self {
            case .duplicateListName:
                return "A list with this name already exists. Please choose a different name."
            }
        }
    }

    // MARK: - Update Task Lists

    public func updateTaskLists() async throws -> [TaskList] {
        try await mergeDuplicateLists()

        let lists = try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.order, ascending: true)]
            return try self.persistentContainer.viewContext.fetch(request)
        }

        taskLists = lists
        WidgetCenter.shared.reloadTimelines(ofKind: "HexagonWidget")
        return taskLists
    }
    
    public func getRemindersCountForList(_ taskList: TaskList) async -> Int {
            let context = persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "list == %@", taskList)
            
            do {
                let count = try await context.perform {
                    try context.count(for: fetchRequest)
                }
                return count
            } catch {
                print("Error fetching reminder count: \(error)")
                return 0
            }
        }

    // MARK: - Merge Duplicate Lists

    private func mergeDuplicateLists() async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            let allLists = try context.fetch(request)

            let listsByName = Dictionary(grouping: allLists, by: { $0.name ?? "" })

            for (_, lists) in listsByName {
                if lists.count > 1 {
                    guard let mainList = lists.first else { continue }
                    for duplicateList in lists.dropFirst() {
                        if let reminders = duplicateList.reminders as? Set<Reminder> {
                            for reminder in reminders {
                                reminder.list = mainList
                            }
                        }
                  
                        context.delete(duplicateList)
                    }
                }
            }
         
            try context.save()
        }
    }

    // MARK: - Fetch Inbox List

    public func fetchInboxList() async throws -> TaskList {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Inbox")
        request.fetchLimit = 1

        let inboxList = try await context.perform {
            let results = try context.fetch(request)
            if let inbox = results.first {
                return inbox
            } else {
                let inbox = TaskList(context: context)
                inbox.listID = UUID()
                inbox.name = "Inbox"
                inbox.symbol = "tray.fill"
                inbox.colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.gray, requiringSecureCoding: true)
                inbox.order = Int16(self.taskLists.count)
                try context.save()
                return inbox
            }
        }

        return inboxList
    }

    // MARK: - Update Task List

    public func updateTaskList(_ taskList: TaskList, name: String, color: UIColor, symbol: String) async throws {
        guard taskList.name != "Inbox" else { return }
        let context = persistentContainer.viewContext

      
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND self != %@", name, taskList)
        fetchRequest.fetchLimit = 1

        let existingLists = try await context.perform {
            return try context.fetch(fetchRequest)
        }

        if !existingLists.isEmpty {
            throw ListServiceError.duplicateListName
        }

        try await context.perform {
            taskList.name = name
            taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            taskList.symbol = symbol
            try context.save()
        }

        _ = try await updateTaskLists()
    }

    // MARK: - Save Task List

    public func saveTaskList(name: String, color: UIColor, symbol: String) async throws {
        let context = persistentContainer.viewContext

      
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.fetchLimit = 1

        let existingLists = try await context.perform {
            return try context.fetch(fetchRequest)
        }

        if !existingLists.isEmpty {
            throw ListServiceError.duplicateListName
        }

        try await context.perform {
            let taskList = TaskList(context: context)
            taskList.listID = UUID()
            taskList.name = name
            taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            taskList.symbol = symbol
            taskList.order = Int16(self.taskLists.count)
            try context.save()
        }

        _ = try await updateTaskLists()
    }

    // MARK: - Delete Task List

    public func deleteTaskList(_ taskList: TaskList) async throws {
        guard taskList.name != "Inbox" else { return }
        let context = persistentContainer.viewContext
        try await context.perform {
            context.delete(taskList)
            try context.save()
        }
        _ = try await updateTaskLists()
    }

    // MARK: - Reorder Task Lists

    public func reorderLists() async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            for (index, list) in self.taskLists.enumerated() {
                list.order = Int16(index)
            }
            try context.save()
        }
        _ = try await updateTaskLists()
    }

    // MARK: - Ensure Inbox List Exists

    public func ensureInboxListExists() async throws {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", "Inbox")

        let fetchResults = try await context.perform {
            return try context.fetch(request)
        }

        if fetchResults.isEmpty {
            try await context.perform {
                let inbox = TaskList(context: context)
                inbox.listID = UUID()
                inbox.name = "Inbox"
                inbox.symbol = "tray.fill"
                inbox.colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor.gray, requiringSecureCoding: true)
                inbox.order = Int16(self.taskLists.count)
                try context.save()
            }

            print("Created a new Inbox.")

            _ = try await updateTaskLists()
        } else {
            print("Inbox already exists.")
        }
    }
}
