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
        subheadingService: SubheadingService(persistenceController: PersistenceController.shared)
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
        tags: Set<ReminderTag>,
        photos: [UIImage],
        notifications: Set<String>,
        location: CLLocationCoordinate2D?,
        radius: Double?,
        voiceNoteData: Data?
    ) async throws -> Reminder {
        logger.info("Saving reminder: title=\(title), list=\(list?.name ?? "No List")")
        
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        let savedReminder = try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let reminderToSave = self.getOrCreateReminder(reminder: reminder, context: context)
                    
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
                    
                    self.handleReminderPhotos(reminderToSave: reminderToSave, photos: photos, context: context)
                    self.handleReminderLocation(reminderToSave: reminderToSave, location: location, radius: radius, context: context)
                    self.setReminderVoiceNote(reminderToSave: reminderToSave, voiceNoteData: voiceNoteData, context: context)
                    
                    try context.save()
                    
                    self.logger.info("Saved reminder: id=\(reminderToSave.reminderID?.uuidString ?? "unknown"), title=\(reminderToSave.title ?? ""), isInInbox=\(reminderToSave.isInInbox), list=\(reminderToSave.list?.name ?? "No List"), isCompleted=\(reminderToSave.isCompleted)")
                    
                    continuation.resume(returning: reminderToSave)
                } catch {
                    self.logger.error("Failed to save reminder: \(error.localizedDescription)")
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await postSaveOperations(for: savedReminder)
        
        return savedReminder
    }
    
    public func fetchReminders(
        withPredicate predicateFormat: String? = nil,
        predicateArguments: [Any] = [],
        excludeCompleted: Bool = false,
        sortKey: String? = nil,
        ascending: Bool = true
    ) async throws -> [Reminder] {
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            
            var predicates = [NSPredicate]()
            
            if let predicateFormat = predicateFormat {
                predicates.append(NSPredicate(format: predicateFormat, argumentArray: predicateArguments))
            }
            
            if excludeCompleted {
                predicates.append(NSPredicate(format: "isCompleted == NO"))
            }
            
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            request.sortDescriptors = [NSSortDescriptor(key: sortKey ?? "startDate", ascending: ascending)]
            
            let fetchedReminders = try self.persistentContainer.viewContext.fetch(request)
            self.logger.info("Fetched \(fetchedReminders.count) reminders with predicates.")
            return fetchedReminders
        }
    }
    
    public func getReminder(withID objectID: NSManagedObjectID) throws -> Reminder {
        let context = persistentContainer.viewContext
        guard let reminder = try context.existingObject(with: objectID) as? Reminder else {
            throw NSError(domain: "com.klynch.Hexagon", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reminder not found"])
        }
        return reminder
    }
    
    public func getRemindersForList(_ list: TaskList) async throws -> [Reminder] {
        logger.info("Fetching reminders for list: \(list.name ?? "Unknown"), listID: \(list.listID?.uuidString ?? "nil")")
        let reminders = try await fetchReminders(
            withPredicate: "list == %@",
            predicateArguments: [list]
        )
        logger.info("Fetched \(reminders.count) reminders for list")
        for reminder in reminders {
            logger.debug("Reminder: id=\(reminder.reminderID?.uuidString ?? "nil"), title=\(reminder.title ?? "nil"), isCompleted=\(reminder.isCompleted)")
        }
        return reminders
    }
    
    public func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async throws {
        logger.info("Updating completion status: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? ""), isCompleted=\(isCompleted)")
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            let reminderInContext = context.object(with: reminder.objectID) as! Reminder
            reminderInContext.isCompleted = isCompleted
            try context.save()
        }
        
        await refreshReminders()
    }
    
    public func updateReminder(_ reminder: Reminder) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            _ = context.object(with: reminder.objectID) as! Reminder
            try context.save()
        }
        await refreshReminders()
    }
    
    public func moveReminder(_ reminder: Reminder, to subHeading: SubHeading?) async throws {
        try await subheadingService.moveReminder(reminder, to: subHeading)
        await refreshReminders()
    }
    
    public func deleteReminder(_ reminder: Reminder) async throws {
        logger.info("Deleting reminder: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? "")")
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            let reminderInContext = context.object(with: reminder.objectID) as! Reminder
            context.delete(reminderInContext)
            try context.save()
        }
        await refreshReminders()
    }
    
    public func reorderReminders(_ reminders: [Reminder]) async throws {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        
        try await context.perform {
            for (index, reminder) in reminders.enumerated() {
                let reminderInContext = context.object(with: reminder.objectID) as! Reminder
                reminderInContext.order = Int16(index)
            }
            try context.save()
        }
        
        await refreshReminders()
    }
    
    private func setReminders(_ reminders: [Reminder]) {
        self.reminders = reminders
    }
    
    private func getOrCreateReminder(reminder: Reminder?, context: NSManagedObjectContext) -> Reminder {
        if let existingReminder = reminder {
            return context.object(with: existingReminder.objectID) as! Reminder
        } else {
            let newReminder = Reminder(context: context)
            newReminder.reminderID = UUID()
            return newReminder
        }
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
        tags: Set<ReminderTag>,
        notifications: Set<String>
    ) {
        let context = reminderToSave.managedObjectContext!

        reminderToSave.title = title
        reminderToSave.notes = notes
        reminderToSave.url = url
        reminderToSave.priority = priority

        if let list = list {
            let listInContext = context.object(with: list.objectID) as! TaskList
            reminderToSave.list = listInContext
        } else {
            reminderToSave.list = nil
        }

        if let subHeading = subHeading {
            let subHeadingInContext = context.object(with: subHeading.objectID) as? SubHeading
            reminderToSave.subHeading = subHeadingInContext
        } else {
            reminderToSave.subHeading = nil
        }

        let tagsInContext = tags.compactMap { tag -> ReminderTag? in
            return context.object(with: tag.objectID) as? ReminderTag
        }
        reminderToSave.tags = NSSet(array: tagsInContext)

        reminderToSave.notifications = notifications.joined(separator: ",")

        let calendar = Calendar.current
        reminderToSave.startDate = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate))

        if let endDate = endDate {
            reminderToSave.endDate = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate))
        } else {
            reminderToSave.endDate = nil
        }

        reminderToSave.isInInbox = (list == nil)
    }

    
    private func handleReminderPhotos(reminderToSave: Reminder, photos: [UIImage], context: NSManagedObjectContext) {
        if let existingPhotos = reminderToSave.photos as? Set<ReminderPhoto> {
            for photo in existingPhotos {
                context.delete(photo)
            }
            reminderToSave.photos = nil
        }
        
        let reminderPhotos = photos.map { photo -> ReminderPhoto in
            let reminderPhoto = ReminderPhoto(context: context)
            reminderPhoto.photoData = photo.pngData()
            return reminderPhoto
        }
        reminderToSave.photos = NSSet(array: reminderPhotos)
    }
    
    private func handleReminderLocation(reminderToSave: Reminder, location: CLLocationCoordinate2D?, radius: Double?, context: NSManagedObjectContext) {
        if let location = location, let radius = radius {
            let locationEntity = Location(context: context)
            locationEntity.latitude = location.latitude
            locationEntity.longitude = location.longitude
            locationEntity.name = "Reminder Location"
            reminderToSave.location = locationEntity
            reminderToSave.radius = NSNumber(value: radius)
        } else {
            reminderToSave.location = nil
            reminderToSave.radius = nil
        }
    }

    private func postSaveOperations(for savedReminder: Reminder) async {
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        locationService.startMonitoringLocation(for: savedReminder)
        await refreshReminders()
    }
    
    private func setReminderVoiceNote(
        reminderToSave: Reminder,
        voiceNoteData: Data?,
        context: NSManagedObjectContext
    ) {
        if let voiceNoteData = voiceNoteData {
            let voiceNote = reminderToSave.voiceNote ?? VoiceNote(context: context)
            voiceNote.audioData = voiceNoteData
            reminderToSave.voiceNote = voiceNote
        } else if let voiceNote = reminderToSave.voiceNote {
            context.delete(voiceNote)
            reminderToSave.voiceNote = nil
        }
    }
    
    private func refreshReminders() async {
            do {
                let updatedReminders = try await fetchReminders()
                setReminders(updatedReminders)
                logger.info("Refreshed reminders, new count: \(updatedReminders.count)")
            } catch {
                logger.error("Failed to refresh reminders: \(error.localizedDescription)")
            }
        }
    }

    public extension Notification.Name {
        static let reminderAdded = Notification.Name("reminderAdded")
    }
