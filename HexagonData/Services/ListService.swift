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
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    @Published public private(set) var taskLists: [TaskList] = []
    
    public func updateTaskLists() async throws -> [TaskList] {
        let lists = try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.order, ascending: true)]
            return try self.persistentContainer.viewContext.fetch(request)
        }
        taskLists = lists
        WidgetCenter.shared.reloadTimelines(ofKind: "HexagonWidget")
        return lists
    }
    
    public func updateTaskList(_ taskList: TaskList, name: String, color: UIColor, symbol: String) async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            taskList.name = name
            taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
            taskList.symbol = symbol
            try context.save()
        }
        
        _ = try await updateTaskLists()
    }
    
    public func saveTaskList(name: String, color: UIColor, symbol: String) async throws {
        let context = persistentContainer.viewContext
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
    
    public func deleteTaskList(_ taskList: TaskList) async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            context.delete(taskList)
            try context.save()
        }
        _ = try await updateTaskLists()
    }
    
    public func getRemindersCountForList(_ list: TaskList) async -> Int {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "list == %@", list)
        
        do {
            let count = try await persistentContainer.viewContext.perform {
                try self.persistentContainer.viewContext.count(for: request)
            }
            return count
        } catch {
            print("Failed to get reminders count for list: \(error.localizedDescription)")
            return 0
        }
    }
    
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
}
