//
//  AppIntents.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import Foundation
import CoreData
import AppIntents
import UIKit
import SwiftUI
import MapKit

public struct ToggleTaskCompletionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Task Completion"
    public static var description = IntentDescription(
        "Toggle the completion status of a task",
        resultValueName: "Updated Task"
    )
    
    @Parameter(title: "Task ID")
    public var taskID: String
    
    public init() {}
    
    public init(taskID: String) {
        self.taskID = taskID
    }
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Toggle completion for task with ID \(\.$taskID)")
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let viewContext = PersistenceController.shared.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderID == %@", taskID as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let reminders = try viewContext.fetch(fetchRequest)
            if let reminder = reminders.first {
                reminder.isCompleted.toggle()
                try viewContext.save()
                return .result(dialog: "Task '\(reminder.title ?? "Untitled Task")' marked as \(reminder.isCompleted ? "complete" : "incomplete").")
            } else {
                throw IntentError.taskNotFound
            }
        } catch {
            throw IntentError.unableToToggle
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case taskNotFound
        case unableToToggle
        
        public var description: String {
            switch self {
            case .taskNotFound:
                return "The specified task could not be found."
            case .unableToToggle:
                return "Unable to toggle the task's completion status."
            }
        }
    }
}

public struct AddNewTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add New Task"
    public static var description = IntentDescription(
        "Add a new task to your list",
        resultValueName: "New Task"
    )
    
    @Parameter(title: "Task Title")
    public var taskTitle: String
    
    @Parameter(title: "List", optionsProvider: TaskListOptionsProvider())
    public var taskList: TaskListEntity?
    
    @Parameter(title: "Due Date")
    public var dueDate: Date?
    
    @Parameter(title: "Priority", optionsProvider: PriorityOptionsProvider())
    public var priority: PriorityEntity?
    
    @Parameter(title: "Tags")
    public var tags: [TagEntity]
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Add task") {
            \.$taskTitle
            \.$taskList
        }
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let reminderService = ReminderService.shared
        
        let context = reminderService.persistentContainer.viewContext
        
        do {
            let savedReminder = try await reminderService.saveReminder(
                title: taskTitle,
                startDate: Date(),
                endDate: dueDate,
                notes: nil,
                url: nil,
                priority: Int16(priority?.id ?? 0),
                list: taskList.map { _ in TaskList(context: context) },
                subHeading: nil,
                tags: Set(tags.compactMap { _ in Tag(context: context) }),
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            return .result(dialog: "Task '\(savedReminder.title ?? taskTitle)' added successfully with ID: \(savedReminder.reminderID?.uuidString ?? "Unknown").")
        } catch {
            throw IntentError.unableToSave
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case unableToSave
        
        public var description: String {
            switch self {
            case .unableToSave:
                return "Unable to save the new task. Please try again."
            }
        }
    }
}

public struct MarkTaskCompleteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Mark Task Complete"
    public static var description = IntentDescription(
        "Mark a task as complete",
        resultValueName: "Completed Task"
    )
    
    @Parameter(title: "Task", optionsProvider: ReminderOptionsProvider())
    public var task: ReminderEntity
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Mark '\(\.$task)' as complete")
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let viewContext = PersistenceController.shared.persistentContainer.viewContext
        _ = ReminderService.shared
        
        do {
            try await viewContext.perform {
                let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "identifier == %@", task.id as CVarArg)
                
                if let reminder = try viewContext.fetch(fetchRequest).first {
                    reminder.isCompleted = true
                    try viewContext.save()
                } else {
                    throw IntentError.taskNotFound
                }
            }
            return .result(dialog: "Task '\(task.title)' marked as complete.")
        } catch {
            throw IntentError.unableToComplete
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case taskNotFound
        case unableToComplete
        
        public var description: String {
            switch self {
            case .taskNotFound:
                return "The specified task could not be found."
            case .unableToComplete:
                return "Unable to mark the task as complete. Please try again."
            }
        }
    }
}

public struct AddNewListIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add New List"
    public static var description = IntentDescription(
        "Add a new task list",
        resultValueName: "New List"
    )
    
    @Parameter(title: "List Name")
    public var listName: String
    
    @Parameter(title: "Color")
    public var color: ColorEntity?
    
    @Parameter(title: "Symbol")
    public var symbol: String?
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Add new list '\(\.$listName)'")
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let viewContext = PersistenceController.shared.persistentContainer.viewContext
        _ = ReminderService.shared
        
        do {
            let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.order, ascending: false)]
            fetchRequest.fetchLimit = 1
            let highestOrderList = try viewContext.fetch(fetchRequest).first
            let nextOrder = (highestOrderList?.order ?? -1) + 1
            
            let taskList = TaskList(context: viewContext)
            taskList.name = listName
            taskList.listID = UUID()
            taskList.colorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color?.color ?? .blue), requiringSecureCoding: true)
            taskList.symbol = symbol ?? "list.bullet"
            taskList.order = nextOrder
            
            try viewContext.save()
            
            return .result(dialog: "New list '\(listName)' added successfully.")
        } catch {
            throw IntentError.unableToSave
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case unableToSave
        
        public var description: String {
            return "Unable to save the new list. Please try again."
        }
    }
}

public struct MoveTaskIntent: AppIntent {
    public static var title: LocalizedStringResource = "Move Task"
    public static var description = IntentDescription(
        "Move a task to a different list",
        resultValueName: "Moved Task"
    )
    
    @Parameter(title: "Task", optionsProvider: ReminderOptionsProvider())
    public var task: ReminderEntity
    
    @Parameter(title: "Destination List", optionsProvider: TaskListOptionsProvider())
    public var destinationList: TaskListEntity
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Move '\(\.$task)' to \(\.$destinationList)")
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let viewContext = PersistenceController.shared.persistentContainer.viewContext
        
        do {
            let reminderFetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            reminderFetchRequest.predicate = NSPredicate(format: "identifier == %@", task.id as CVarArg)
            
            let listFetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            listFetchRequest.predicate = NSPredicate(format: "id == %@", destinationList.id as CVarArg)
            
            guard let reminder = try viewContext.fetch(reminderFetchRequest).first,
                  let list = try viewContext.fetch(listFetchRequest).first else {
                throw IntentError.entityNotFound
            }
            
            reminder.list = list
            try viewContext.save()
            
            return .result(dialog: "Task '\(task.title)' moved to '\(destinationList.name)'.")
        } catch {
            throw IntentError.unableToMove
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case entityNotFound
        case unableToMove
        
        public var description: String {
            switch self {
            case .entityNotFound:
                return "The specified task or list could not be found."
            case .unableToMove:
                return "Unable to move the task. Please try again."
            }
        }
    }
}

public struct GetTasksFromListIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Tasks from List"
    public static var description = IntentDescription(
        "Retrieve tasks from a specific list",
        resultValueName: "Task List"
    )
    
    @Parameter(title: "List", optionsProvider: TaskListOptionsProvider())
    public var list: TaskListEntity
    
    public init() {}
    
    public static var parameterSummary: some ParameterSummary {
        Summary("Get tasks from \(\.$list)")
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let reminderService = ReminderService.shared
        let viewContext = reminderService.persistentContainer.viewContext
        
        do {
            let listFetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            listFetchRequest.predicate = NSPredicate(format: "id == %@", list.id as CVarArg)
            
            guard let taskList = try viewContext.fetch(listFetchRequest).first else {
                throw IntentError.listNotFound
            }
            
            let reminders = try await reminderService.getRemindersForList(taskList)
            
            let reminderEntities = reminders.compactMap { reminder -> ReminderEntity? in
                guard let id = reminder.reminderID, let title = reminder.title else { return nil }
                return ReminderEntity(id: id, title: title, isCompleted: reminder.isCompleted, dueDate: reminder.endDate)
            }
            
            let taskCount = reminderEntities.count
            let taskWord = taskCount == 1 ? "task" : "tasks"
            
            return .result(dialog: "Found \(taskCount) \(taskWord) in '\(list.name)'.")
        } catch {
            throw IntentError.unableToFetchTasks
        }
    }
    
    public enum IntentError: Error, CustomStringConvertible {
        case listNotFound
        case unableToFetchTasks
        
        public var description: String {
            switch self {
            case .listNotFound:
                return "The specified list could not be found."
            case .unableToFetchTasks:
                return "Unable to fetch tasks from the list. Please try again."
            }
        }
    }
}

public struct TaskListOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [TaskListEntity] {
        let reminderService = await ReminderService.shared
        
        let fetchRequest: NSFetchRequest<TaskList> = TaskList.fetchRequest()
        let taskLists = try await reminderService.persistentContainer.viewContext.perform {
            try reminderService.persistentContainer.viewContext.fetch(fetchRequest)
        }
        return taskLists.compactMap { taskList -> TaskListEntity? in
            guard let id = taskList.listID, let name = taskList.name, let colorData = taskList.colorData else { return nil }
            let color = (try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)) ?? .blue
            return TaskListEntity(id: id, name: name, color: ColorEntity(id: UUID(), color: Color(uiColor: color)), symbol: taskList.symbol ?? "list.bullet")
        }
    }
}

public struct ReminderOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [ReminderEntity] {
        let viewContext = PersistenceController.shared.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        let reminders = try viewContext.fetch(fetchRequest)
        return reminders.compactMap { reminder in
            guard let id = reminder.reminderID, let title = reminder.title else { return nil }
            return ReminderEntity(id: id, title: title, isCompleted: reminder.isCompleted, dueDate: reminder.endDate)
        }
    }
}

public struct PriorityOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [PriorityEntity] {
        return [
            PriorityEntity(id: 0, name: "No Priority"),
            PriorityEntity(id: 1, name: "Low"),
            PriorityEntity(id: 2, name: "Medium"),
            PriorityEntity(id: 3, name: "High")
        ]
    }
}
