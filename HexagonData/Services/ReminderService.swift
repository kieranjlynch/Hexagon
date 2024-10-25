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
    // MARK: - Properties
    public static let shared = ReminderService(
        persistenceController: PersistenceController.shared,
        listService: ListService.shared,
        tagService: TagService.shared,
        calendarService: CalendarService.shared,
        photoService: PhotoService.shared,
        locationService: LocationService(),
        subheadingService: SubheadingService()
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
    
    // MARK: - Initialization
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
    
    // MARK: - Create
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
        
        let savedReminder = try await withCheckedThrowingContinuation { continuation in
            persistentContainer.viewContext.perform {
                do {
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
                    
                    self.handleReminderPhotos(reminderToSave: reminderToSave, photos: photos)
                    self.handleReminderLocation(reminderToSave: reminderToSave, location: location, radius: radius)
                    self.setReminderVoiceNote(reminderToSave: reminderToSave, voiceNoteData: voiceNoteData)
                    
                    try self.persistentContainer.viewContext.save()
                    
                    self.logger.info("Saved reminder: id=\(reminderToSave.reminderID?.uuidString ?? "unknown"), title=\(reminderToSave.title ?? ""), list=\(reminderToSave.list?.name ?? "No List"), isCompleted=\(reminderToSave.isCompleted)")
                    
                    continuation.resume(returning: reminderToSave)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        await postSaveOperations(for: savedReminder)
        
        if let endDate = endDate {
            try await calendarService.saveTaskToCalendar(title: savedReminder.title ?? "", startDate: savedReminder.startDate ?? Date(), duration: endDate.timeIntervalSince(savedReminder.startDate ?? Date()) / 60)
        }
        
        return savedReminder
    }
    
    // MARK: - Read
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
            
            request.sortDescriptors = [NSSortDescriptor(key: sortKey ?? "startDate", ascending: ascending)]
            
            let fetchedReminders = try self.persistentContainer.viewContext.fetch(request)
            self.logger.info("Fetched \(fetchedReminders.count) reminders with predicate: \(predicateFormat ?? "None")")
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
        return try await fetchReminders(
            withPredicate: "list == %@",
            predicateArguments: [list]
        )
    }
    
    // MARK: - Update
    public func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async throws {
        logger.info("Updating completion status: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? ""), isCompleted=\(isCompleted)")
        let context = persistentContainer.viewContext
        try await context.perform {
            reminder.isCompleted = isCompleted
            try context.save()
        }
        
        await refreshReminders()
    }
    
    public func updateReminder(_ reminder: Reminder) async throws {
        let context = persistentContainer.viewContext
        try await context.perform {
            try context.save()
        }
        await refreshReminders()
    }
    
    public func moveReminder(_ reminder: Reminder, to subHeading: SubHeading?) async throws {
        try await subheadingService.moveReminder(reminder, to: subHeading)
        await refreshReminders()
    }
    
    // MARK: - Delete
    public func deleteReminder(_ reminder: Reminder) async throws {
        logger.info("Deleting reminder: id=\(reminder.reminderID?.uuidString ?? "unknown"), title=\(reminder.title ?? "")")
        let context = persistentContainer.viewContext
        try await context.perform { [self] in
            context.delete(reminder)
            do {
                try context.save()
            } catch {
                logger.error("Failed to delete reminder: \(error.localizedDescription)")
                context.rollback()
                throw error
            }
        }
        await refreshReminders()
    }
    
    // MARK: - Sort
    public func reorderReminders(_ reminders: [Reminder]) async throws {
        let context = persistentContainer.viewContext
        
        try await context.perform {
            for (index, reminder) in reminders.enumerated() {
                reminder.order = Int16(index)
            }
            try context.save()
        }
        
        await refreshReminders()
    }
    
    // MARK: - Helper Methods
    private func setReminders(_ reminders: [Reminder]) {
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
        reminderToSave.title = title
        reminderToSave.notes = notes
        reminderToSave.url = url
        reminderToSave.priority = priority
        reminderToSave.list = list
        reminderToSave.subHeading = subHeading
        reminderToSave.tags = tags as NSSet
        reminderToSave.notifications = notifications.joined(separator: ",")
        
        let calendar = Calendar.current
        reminderToSave.startDate = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate))
        
        if let endDate = endDate {
            reminderToSave.endDate = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate))
        } else {
            reminderToSave.endDate = nil
        }
    }
    
    private func handleReminderPhotos(reminderToSave: Reminder, photos: [UIImage]) {
        let reminderPhotos = photos.map { photo -> ReminderPhoto in
            let reminderPhoto = ReminderPhoto(context: self.persistentContainer.viewContext)
            reminderPhoto.photoData = photo.pngData()
            return reminderPhoto
        }
        reminderToSave.photos = NSSet(array: reminderPhotos)
    }
    
    private func handleReminderLocation(reminderToSave: Reminder, location: CLLocationCoordinate2D?, radius: Double?) {
        if let location = location, let radius = radius {
            let locationEntity = Location(context: self.persistentContainer.viewContext)
            locationEntity.latitude = location.latitude
            locationEntity.longitude = location.longitude
            locationEntity.name = "Reminder Location"
            reminderToSave.location = locationEntity
            reminderToSave.radius = radius
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
    
    private func postSaveOperations(for savedReminder: Reminder) async {
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        locationService.startMonitoringLocation(for: savedReminder)
        await refreshReminders()
    }
    
    private func refreshReminders() async {
        do {
            let updatedReminders = try await fetchReminders()
            setReminders(updatedReminders)
        } catch {
            logger.error("Failed to refresh reminders: \(error.localizedDescription)")
        }
    }
}

public extension Notification.Name {
    static let reminderAdded = Notification.Name("reminderAdded")
}
