//
//  ReminderService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import Foundation
import CoreData
import os
import Combine
import UIKit
import CoreLocation

@MainActor
public class ReminderService: ObservableObject {
    public static let shared = ReminderService(
        persistenceController: PersistenceController.shared,
        listService: ListService.shared,
        tagService: TagService.shared,
        calendarService: CalendarService.shared,
        photoService: PhotoService.shared,
        locationService: LocationService(),
        subheadingService: SubheadingService(context: PersistenceController.shared.persistentContainer.viewContext)
    )
    
    public let persistentContainer: NSPersistentContainer
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.klynch.Hexagon", category: "ReminderService")
    
    @Published public private(set) var reminders: [Reminder] = []
    
    private let listService: ListService
    private let tagService: TagService
    private let calendarService: CalendarService
    private let photoService: PhotoService
    private let locationService: LocationService
    private let subheadingService: SubheadingService
    
    public init(
        persistenceController: PersistenceController,
        listService: ListService,
        tagService: TagService,
        calendarService: CalendarService,
        photoService: PhotoService,
        locationService: LocationService,
        subheadingService: SubheadingService
    ) {
        self.persistentContainer = persistenceController.persistentContainer
        self.listService = listService
        self.tagService = tagService
        self.calendarService = calendarService
        self.photoService = photoService
        self.locationService = locationService
        self.subheadingService = subheadingService
    }
    
    public func initialize() async {
        do {
            let reminders = try await fetchReminders()
            setReminders(reminders)
            _ = try await listService.updateTaskLists()
        } catch {
            logger.error("Initialization error: \(error.localizedDescription)")
        }
    }
    
    public func saveReminder(
        reminder: Reminder? = nil,
        title: String,
        startDate: Date,
        endDate: Date?,
        notes: String?,
        url: String?,
        priority: Int16,
        list: TaskList?,
        subHeading: SubHeading?,
        tags: Set<Tag>,
        photos: [UIImage],
        notifications: Set<String>,
        location: CLLocationCoordinate2D?,
        radius: Double?,
        voiceNoteData: Data?
    ) async throws -> Reminder {
        logger.info("Saving reminder: title=\(title), list=\(list?.name ?? "No List")")
        
        let savedReminder = try await persistentContainer.viewContext.perform {
            let reminderToSave = self.getOrCreateReminder(reminder: reminder, context: self.persistentContainer.viewContext)
            
            if reminderToSave.reminderID == nil {
                reminderToSave.reminderID = UUID()
            }
            
            self.setReminderProperties(
                reminderToSave: reminderToSave,
                title: title,
                startDate: startDate,
                endDate: endDate,
                notes: notes,
                url: url,
                priority: priority,
                list: list,
                subHeading: subHeading,
                tags: tags,
                notifications: notifications
            )
            
            reminderToSave.isInInbox = (list == nil)
            print("Saving reminder: \(reminderToSave.title ?? "Untitled"), isInInbox: \(reminderToSave.isInInbox), list: \(reminderToSave.list?.name ?? "None")")
            
            try self.persistentContainer.viewContext.save()
            
            self.logger.info("Saved reminder: id=\(reminderToSave.reminderID?.uuidString ?? "unknown"), title=\(reminderToSave.title ?? ""), isInInbox=\(reminderToSave.isInInbox), list=\(reminderToSave.list?.name ?? "No List"), isCompleted=\(reminderToSave.isCompleted)")
            
            return reminderToSave
        }

        let allReminders = try await fetchReminders()
        logger.info("Total reminders after saving: \(allReminders.count)")
        for reminder in allReminders {
            logger.info("After save - All reminders: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? ""), isInInbox=\(reminder.isInInbox), isCompleted=\(reminder.isCompleted)")
        }
        
        return savedReminder
    }
    
    private func setReminderProperties(
        reminderToSave: Reminder,
        title: String,
        startDate: Date,
        endDate: Date?,
        notes: String?,
        url: String?,
        priority: Int16,
        list: TaskList?,
        subHeading: SubHeading?,
        tags: Set<Tag>,
        notifications: Set<String>
    ) {
        reminderToSave.title = title
        reminderToSave.notes = notes
        reminderToSave.url = url
        reminderToSave.priority = priority
        reminderToSave.list = list
        reminderToSave.subHeading = subHeading
        reminderToSave.tags = tags as NSSet
        reminderToSave.notifications = notifications.joined(separator: ",")
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)
        reminderToSave.startDate = calendar.date(from: startComponents)
        
        if let endDate = endDate {
            let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)
            reminderToSave.endDate = calendar.date(from: endComponents)
        } else {
            reminderToSave.endDate = nil
        }
        
        reminderToSave.isInInbox = (list == nil)
    }
    
    private func postSaveOperations(for savedReminder: Reminder) async {
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        
        locationService.startMonitoringLocation(for: savedReminder)
        
        do {
            let updatedReminders = try await fetchReminders()
            setReminders(updatedReminders)
            print("Fetched and updated reminders after saving. Count: \(updatedReminders.count)")
        } catch {
            logger.error("Failed to fetch reminders after saving: \(error.localizedDescription)")
        }
    }
    
    public func reorderReminders(_ reminders: [Reminder]) async throws {
        let context = persistentContainer.viewContext
        
        try await context.perform {
            for (index, reminder) in reminders.enumerated() {
                reminder.order = Int16(index)
            }
            try context.save()
        }
        
        let updatedReminders = try await fetchReminders()
        setReminders(updatedReminders)
    }
    
    public func setReminders(_ reminders: [Reminder]) {
        self.reminders = reminders
    }
    
    private func getOrCreateReminder(reminder: Reminder?, context: NSManagedObjectContext) -> Reminder {
        if let existingReminder = reminder {
            return existingReminder
        } else {
            let newReminder = Reminder(context: context)
            newReminder.reminderID = UUID()
            return newReminder
        }
    }
    
    private func setReminderVoiceNote(
        reminderToSave: Reminder,
        voiceNoteData: Data?
    ) {
        let context = persistentContainer.viewContext
        if let voiceNoteData = voiceNoteData {
            let voiceNote = reminderToSave.voiceNote ?? VoiceNote(context: context)
            voiceNote.audioData = voiceNoteData
            reminderToSave.voiceNote = voiceNote
        } else if reminderToSave.voiceNote != nil {
            context.delete(reminderToSave.voiceNote!)
            reminderToSave.voiceNote = nil
        }
    }
    
    public func fetchAllReminders() async throws -> [Reminder] {
        logger.info("Starting to fetch all reminders")
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = nil
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.startDate, ascending: true)]
            
            do {
                let fetchedReminders = try self.persistentContainer.viewContext.fetch(request)
                self.logger.info("Fetched \(fetchedReminders.count) reminders")
                fetchedReminders.forEach { reminder in
                    print("Fetched reminder: \(reminder.title ?? "Untitled"), List: \(reminder.list?.name ?? "No List"), IsCompleted: \(reminder.isCompleted)")
                }
                return fetchedReminders
            } catch {
                self.logger.error("Failed to fetch reminders: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    public func debugInboxReminders() async {
        do {
            let context = persistentContainer.viewContext
            let inboxCount = try await context.perform {
                let checkInboxRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
                checkInboxRequest.predicate = NSPredicate(format: "isInInbox == YES")
                return try context.count(for: checkInboxRequest)
            }
            print("Number of reminders in inbox: \(inboxCount)")

            let unassignedCount = try await context.perform {
                let unassignedRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
                unassignedRequest.predicate = NSPredicate(format: "list == nil")
                return try context.count(for: unassignedRequest)
            }
            print("Number of unassigned reminders: \(unassignedCount)")

            let allReminders = try await fetchAllReminders()
            print("Total number of reminders: \(allReminders.count)")
            for reminder in allReminders {
                print("Reminder: \(reminder.title ?? "Untitled"), isInInbox: \(reminder.isInInbox), list: \(reminder.list?.name ?? "None"), isCompleted: \(reminder.isCompleted)")
            }
        } catch {
            print("Error debugging inbox reminders: \(error)")
        }
    }
    
    public func fetchUnassignedAndIncompleteReminders() async throws -> [Reminder] {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let allRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            let allReminders = try context.fetch(allRequest)
            print("All reminders:")
            for reminder in allReminders {
                print("Reminder: \(reminder.title ?? "Untitled"), isInInbox: \(reminder.isInInbox), list: \(reminder.list?.name ?? "None"), isCompleted: \(reminder.isCompleted)")
            }

            let inboxPredicate = NSPredicate(format: "isInInbox == YES")
            let unassignedPredicate = NSPredicate(format: "list == nil")
            let incompletePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "isCompleted == NO"),
                NSPredicate(format: "isCompleted == nil")
            ])

            let inboxRequest = Reminder.fetchRequest()
            inboxRequest.predicate = inboxPredicate
            let inboxReminders = try context.fetch(inboxRequest)
            print("Inbox reminders: \(inboxReminders.count)")

            let unassignedRequest = Reminder.fetchRequest()
            unassignedRequest.predicate = unassignedPredicate
            let unassignedReminders = try context.fetch(unassignedRequest)
            print("Unassigned reminders: \(unassignedReminders.count)")

            let incompleteRequest = Reminder.fetchRequest()
            incompleteRequest.predicate = incompletePredicate
            let incompleteReminders = try context.fetch(incompleteRequest)
            print("Incomplete reminders: \(incompleteReminders.count)")
            print("Incomplete reminders details:")
            for reminder in incompleteReminders {
                print("Reminder: \(reminder.title ?? "Untitled"), isCompleted: \(reminder.isCompleted)")
            }

            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSCompoundPredicate(orPredicateWithSubpredicates: [inboxPredicate, unassignedPredicate]),
                incompletePredicate
            ])

            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = combinedPredicate
            let reminders = try context.fetch(request)
            print("Combined predicate found \(reminders.count) reminders")
            for reminder in reminders {
                print("Found reminder: \(reminder.title ?? "Untitled"), isInInbox: \(reminder.isInInbox), list: \(reminder.list?.name ?? "None"), isCompleted: \(reminder.isCompleted)")
            }

            return reminders
        }
    }
    
    public func fetchReminders(
        withPredicate predicateFormat: String? = nil,
        predicateArguments: [Any] = [],
        sortKey: String? = nil,
        ascending: Bool = true
    ) async throws -> [Reminder] {
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            
            if let predicateFormat = predicateFormat {
                request.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArguments)
            }
            
            if let sortKey = sortKey {
                request.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]
            } else {
                request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.startDate, ascending: true)]
            }
            
            do {
                let fetchedReminders = try self.persistentContainer.viewContext.fetch(request)
                self.logger.info("Fetched \(fetchedReminders.count) reminders with predicate: \(predicateFormat ?? "None")")
                for reminder in fetchedReminders {
                    self.logger.info("Fetched reminder: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? ""), isInInbox=\(reminder.isInInbox), isCompleted=\(reminder.isCompleted), list=\(reminder.list?.name ?? "No List")")
                }
                return fetchedReminders
            } catch {
                self.logger.error("Failed to fetch reminders: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    public func getReminder(withID objectID: NSManagedObjectID) throws -> Reminder {
        let context = persistentContainer.viewContext
        guard let reminder = try context.existingObject(with: objectID) as? Reminder else {
            throw NSError(domain: "com.klynch.Hexagon", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reminder not found"])
        }
        return reminder
    }
    
    public func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async throws {
        logger.info("Updating completion status: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? ""), isCompleted=\(isCompleted)")
        let context = persistentContainer.viewContext
        try await context.perform {
            reminder.isCompleted = isCompleted
            try context.save()
        }
        
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        let updatedReminders = try await fetchReminders()
        setReminders(updatedReminders)
    }
    
    public func deleteReminder(_ reminder: Reminder) async throws {
        logger.info("Deleting reminder: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? "")")
        let context = persistentContainer.viewContext
        try await context.perform {
            context.delete(reminder)
            try context.save()
        }
        
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        let updatedReminders = try await fetchReminders()
        setReminders(updatedReminders)
    }
    
    public func fetchUnassignedReminders() async throws -> [Reminder] {
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        request.predicate = NSPredicate(format: "list == nil AND isCompleted == false")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.startDate, ascending: true)]
        
        return try await persistentContainer.viewContext.perform {
            try self.persistentContainer.viewContext.fetch(request)
        }
    }
    
    public func getRemindersForList(_ list: TaskList) async throws -> [Reminder] {
        print("Fetching reminders for list: \(list.name ?? "Unnamed List")")
        let reminders = try await fetchReminders(
            withPredicate: "list == %@",
            predicateArguments: [list]
        )
        print("Fetched \(reminders.count) reminders for list \(list.name ?? "Unnamed List")")
        return reminders
    }
    
    public func getUnassignedAndIncompleteReminders() -> [Reminder] {
        return reminders.filter { $0.list == nil && !$0.isCompleted }
    }
}

public extension Notification.Name {
    static let reminderAdded = Notification.Name("reminderAdded")
}
