//
//  ListDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import SwiftUI
import CoreData
import CoreLocation
import HexagonData

@MainActor
public class ListDetailViewModel: ObservableObject {
    @Published public var subHeadings: [SubHeading] = []
    @Published public var reminders: [Reminder] = []
    @Published public var error: IdentifiableError?
    @Published public var listSymbol: String
    
    private let context: NSManagedObjectContext
    public let reminderService: ReminderService
    public let locationService: LocationService
    private let subheadingService: SubheadingService
    public let taskList: TaskList
    
    private var notificationObserver: NSObjectProtocol?
    
    public init(context: NSManagedObjectContext, taskList: TaskList, reminderService: ReminderService, locationService: LocationService) {
        self.context = context
        self.taskList = taskList
        self.reminderService = reminderService
        self.locationService = locationService
        self.subheadingService = SubheadingService(context: context)
        self.listSymbol = taskList.symbol ?? "list.bullet"
        
        setupNotificationObserver()
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .reminderAdded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.refreshRemindersAndSubHeadings()
            }
        }
    }
    
    private func refreshRemindersAndSubHeadings() async {
        await loadContent()
    }
    
    public func loadContent() async {
        do {
            print("Fetching reminders and subheadings for task list: \(taskList.name ?? "")")
            
            let fetchedReminders = try await reminderService.getRemindersForList(taskList)
            
            let fetchedSubHeadings = try await subheadingService.fetchSubHeadings(for: taskList)
            
            await MainActor.run {
                self.reminders = fetchedReminders
                self.subHeadings = fetchedSubHeadings
                
                print("Fetched \(fetchedSubHeadings.count) subheadings and \(fetchedReminders.count) reminders.")
                fetchedSubHeadings.forEach { subHeading in
                    print("Subheading: \(subHeading.title ?? "Untitled")")
                }
            }
        } catch {
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
        }
    }
    
    public func toggleCompletion(_ reminder: Reminder) async {
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await loadContent()
        } catch {
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
        }
    }
    
    public func updateSubHeading(_ subHeading: SubHeading) async throws {
        do {
            try await subheadingService.updateSubHeading(subHeading, title: subHeading.title ?? "")
            await loadContent()
        } catch {
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
            throw error
        }
    }
    
    public func deleteSubHeading(_ subHeading: SubHeading) async throws {
        do {
            try await subheadingService.deleteSubHeading(subHeading)
            await loadContent()
        } catch {
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
            throw error
        }
    }
    
    public func handleDrop(reminders: [Reminder], to subHeading: SubHeading?) async -> Bool {
        do {
            for reminder in reminders {
                reminder.subHeading = subHeading
                reminder.list = self.taskList
            }
            try await context.perform {
                try self.context.save()
            }
            await loadContent()
            return true
        } catch {
            print("Error handling drop: \(error)")
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
            return false
        }
    }
    
    public func handleDropSubheading(_ subHeadings: [SubHeading], to taskList: TaskList) async -> Bool {
        do {
            for subHeading in subHeadings {
                subHeading.taskList = taskList
            }
            try await subheadingService.reorderSubHeadings(self.subHeadings)
            await loadContent()
            return true
        } catch {
            await MainActor.run {
                self.error = IdentifiableError(message: error.localizedDescription)
            }
            return false
        }
    }
    
    public func onDragReminder(_ reminder: Reminder) -> NSItemProvider {
        let objectIDString = reminder.objectID.uriRepresentation().absoluteString
        return NSItemProvider(object: objectIDString as NSString)
    }
    
    public func onDragSubHeading(_ subHeading: SubHeading) -> SubHeading {
        return subHeading
    }
    
    public func onDropReminder(info: DropInfo, subHeading: SubHeading?, items: [Reminder]) async -> Bool {
        return await handleDrop(reminders: items, to: subHeading)
    }
    
    public func onDropSubHeading(info: DropInfo, taskList: TaskList, items: [SubHeading]) async -> Bool {
        return await handleDropSubheading(items, to: taskList)
    }
}
