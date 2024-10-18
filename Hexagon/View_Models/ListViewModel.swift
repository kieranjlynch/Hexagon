//
//  ListViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import Foundation
import SwiftUI
import CoreData
import HexagonData

@MainActor
class ListViewModel: ObservableObject {
    @Published var subHeadings: [SubHeading] = []
    @Published var taskLists: [TaskList] = []
    @Published var selectedFilter: ListFilter = .all
    
    private let context: NSManagedObjectContext
    private let reminderService: ReminderService
    private let subheadingService: SubheadingService
    private let listService = ListService.shared
    
    init(context: NSManagedObjectContext, reminderService: ReminderService) {
        self.context = context
        self.reminderService = reminderService
        self.subheadingService = SubheadingService()
        
        Task {
            await self.loadTaskLists()
        }
    }
    
    func getIncompleteRemindersCount(for taskList: TaskList) -> Int {
        guard let reminders = taskList.reminders?.allObjects as? [Reminder] else {
            return 0
        }
        return reminders.filter { !$0.isCompleted }.count
    }
    
    // MARK: - Task Lists and SubHeadings
    
    func loadTaskLists() async {
        do {
            self.taskLists = try await listService.updateTaskLists()
        } catch {
            print("Failed to load task lists: \(error)")
        }
    }
    
    func deleteTaskList(_ taskList: TaskList) async {
        do {
            try await listService.deleteTaskList(taskList)
            await loadTaskLists()
        } catch {
            print("Error deleting task list: \(error)")
        }
    }
    
    func fetchSubHeadings(for taskList: TaskList?) async {
        guard let taskList = taskList else {
            print("TaskList is nil, cannot fetch subheadings.")
            return
        }
        
        do {
            subHeadings = try await subheadingService.fetchSubHeadings(for: taskList)
        } catch {
            print("Error fetching subheadings: \(error)")
        }
    }
    
    // MARK: - Add, Update, Delete SubHeadings
    
    func addSubHeading(title: String, to taskList: TaskList?) async {
        guard let taskList = taskList else {
            print("Error: TaskList is nil, cannot add subheading.")
            return
        }
        
        do {
            _ = try await subheadingService.saveSubHeading(title: title, taskList: taskList)
            await fetchSubHeadings(for: taskList)
        } catch {
            print("Error adding subheading: \(error)")
        }
    }
    
    func updateSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subheadingService.updateSubHeading(subHeading, title: subHeading.title ?? "")
            await fetchSubHeadings(for: subHeading.taskList)
        } catch {
            print("Error updating subheading: \(error)")
        }
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async {
        do {
            try await subheadingService.deleteSubHeading(subHeading)
            await fetchSubHeadings(for: subHeading.taskList)
        } catch {
            print("Error deleting subheading: \(error)")
        }
    }
    
    // MARK: - Moving and Reordering SubHeadings and Reminders
    
    func moveSubHeadings(from source: IndexSet, to destination: Int) async {
        var revisedSubHeadings = subHeadings
        revisedSubHeadings.move(fromOffsets: source, toOffset: destination)
        
        for (index, subHeading) in revisedSubHeadings.enumerated() {
            subHeading.order = Int16(index)
        }
        
        do {
            try await subheadingService.reorderSubHeadings(revisedSubHeadings)
            subHeadings = revisedSubHeadings
        } catch {
            print("Error moving subheadings: \(error)")
        }
    }
    
    func moveReminders(from source: IndexSet, to destination: Int, in subHeading: SubHeading) async {
        guard let remindersSet = subHeading.reminders as? Set<Reminder> else { return }
        
        var revisedReminders = remindersSet.sorted { $0.order < $1.order }
        revisedReminders.move(fromOffsets: source, toOffset: destination)
        
        for (index, reminder) in revisedReminders.enumerated() {
            reminder.order = Int16(index)
        }
        
        do {
            try await reminderService.reorderReminders(revisedReminders)
        } catch {
            print("Error moving reminders: \(error)")
        }
    }
}
