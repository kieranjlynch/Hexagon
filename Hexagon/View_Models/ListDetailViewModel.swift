//
//  ListDetailViewModel.swift
//  Hexagon
//
//  Created by Kieran Lynch on 17/09/2024.
//

import Foundation
import SwiftUI
import CoreData
import HexagonData
import Combine
import os

@MainActor
class ListDetailViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var subHeadings: [SubHeading] = []
    
    let taskList: TaskList
    let reminderService: ReminderService
    let locationService: LocationService
    private let subheadingService: SubheadingService
    public let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon", category: "ListDetailViewModel")
    
    init(context: NSManagedObjectContext, taskList: TaskList, reminderService: ReminderService, locationService: LocationService) {
        self.context = context
        self.taskList = taskList
        self.reminderService = reminderService
        self.locationService = locationService
        self.subheadingService = SubheadingService(persistenceController: PersistenceController.shared)

        logger.info("ListDetailViewModel initialized for list: \(taskList.name ?? "Unknown")")

        Task {
            await self.fetchReminders()
            await self.fetchSubHeadings()
        }
  
        setupCombineBindings()
    }
    
    func addNewReminder(title: String) async {
        logger.info("Adding new reminder with title: \(title)")
        do {
            let newReminder = try await reminderService.saveReminder(
                title: title,
                startDate: Date(),
                endDate: nil,
                notes: nil,
                url: nil,
                priority: 0,
                list: taskList,
                subHeading: nil,
                tags: [],
                photos: [],
                notifications: [],
                location: nil,
                radius: nil,
                voiceNoteData: nil
            )
            logger.debug("New reminder saved: id=\(newReminder.reminderID?.uuidString ?? "nil"), title=\(newReminder.title ?? "nil")")
            await fetchReminders()
        } catch {
            logger.error("Error creating new reminder: \(error.localizedDescription)")
        }
    }
    
    private func setupCombineBindings() {
        logger.debug("Setting up Combine bindings")
    }
    
    func fetchReminders() async {
        do {
            let fetchedReminders = try await reminderService.getRemindersForList(taskList)
            await MainActor.run {
                self.reminders = fetchedReminders
            }
            print("ViewModel Update - Fetched \(fetchedReminders.count) reminders")
        } catch {
            print("Error fetching reminders: \(error)")
        }
    }
    
    func fetchSubHeadings() async {
        logger.info("Fetching subheadings for list: \(self.taskList.name ?? "Unknown")")
        do {
            let fetchedSubHeadings = try await subheadingService.fetchSubHeadings(for: taskList)
            logger.debug("Fetched \(fetchedSubHeadings.count) subheadings")
            for (index, subHeading) in fetchedSubHeadings.enumerated() {
                logger.debug("Subheading \(index): id=\(subHeading.subheadingID?.uuidString ?? "nil"), title=\(subHeading.title ?? "nil")")
            }
            self.subHeadings = fetchedSubHeadings
        } catch {
            logger.error("Error fetching subheadings: \(error.localizedDescription)")
        }
    }
    
    func toggleCompletion(for reminder: Reminder) async {
        logger.info("Toggling completion for reminder: id=\(reminder.reminderID?.uuidString ?? "nil"), title=\(reminder.title ?? "nil")")
        do {
            try await reminderService.updateReminderCompletionStatus(reminder: reminder, isCompleted: !reminder.isCompleted)
            await fetchReminders()
        } catch {
            logger.error("Error toggling completion: \(error.localizedDescription)")
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async {
        logger.info("Deleting reminder: id=\(reminder.reminderID?.uuidString ?? "nil"), title=\(reminder.title ?? "nil")")
        do {
            try await reminderService.deleteReminder(reminder)
            await fetchReminders()
        } catch {
            logger.error("Error deleting reminder: \(error.localizedDescription)")
        }
    }
    
    func updateSubHeading(_ subHeading: SubHeading) async {
        logger.info("Updating subheading: id=\(subHeading.subheadingID?.uuidString ?? "nil"), title=\(subHeading.title ?? "nil")")
        do {
            try await subheadingService.updateSubHeading(subHeading, title: subHeading.title ?? "")
            await fetchSubHeadings()
        } catch {
            logger.error("Error updating subheading: \(error.localizedDescription)")
        }
    }
    
    func deleteSubHeading(_ subHeading: SubHeading) async {
        logger.info("Deleting subheading: id=\(subHeading.subheadingID?.uuidString ?? "nil"), title=\(subHeading.title ?? "nil")")
        do {
            try await subheadingService.deleteSubHeading(subHeading)
            await fetchSubHeadings()
        } catch {
            logger.error("Error deleting subheading: \(error.localizedDescription)")
        }
    }
    
    func filteredReminders(for subHeading: SubHeading) -> [Reminder] {
        let filtered = reminders.filter { $0.subHeading == subHeading }
        logger.debug("Filtered reminders for subheading \(subHeading.title ?? "nil"): \(filtered.count)")
        return filtered
    }
    
    func handleDrop(reminders: [Reminder], to subHeading: SubHeading) async -> Bool {
        logger.info("Handling drop of \(reminders.count) reminders to subheading: \(subHeading.title ?? "nil")")
        do {
            for reminder in reminders {
                try await reminderService.moveReminder(reminder, to: subHeading)
            }
            await fetchReminders()
            return true
        } catch {
            logger.error("Error handling drop: \(error.localizedDescription)")
            return false
        }
    }
}
