//
//  ReminderService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import Foundation
import CoreData
import CoreLocation
import UIKit
import os
import EventKit
import MapKit
import NotificationCenter
import Combine

@MainActor
public class ReminderService: ObservableObject {
    public static let shared = ReminderService()
    
    public let persistentContainer: NSPersistentContainer
    public let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hexagon", category: "ReminderService")
    
    @Published public private(set) var reminders: [Reminder] = []
    @Published public private(set) var taskLists: [TaskList] = []
    
    private let locationService: LocationService
    private let subheadingService: SubheadingService
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        persistentContainer = persistenceController.persistentContainer
        locationService = LocationService()
        subheadingService = SubheadingService(context: persistentContainer.viewContext)
    }
    
    public func initialize() async {
        do {
            let reminders = try await fetchReminders()
            setReminders(reminders)
            _ = try await updateTaskLists()
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
        print("ReminderService: Saving reminder: \(title), Start: \(startDate), End: \(endDate ?? Date()), List: \(list?.name ?? "No List")")
        
        let savedReminder = try await saveReminderToContext(
            reminder: reminder,
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            url: url,
            priority: priority,
            list: list,
            subHeading: subHeading,
            tags: tags,
            photos: photos,
            notifications: notifications,
            location: location,
            radius: radius,
            voiceNoteData: voiceNoteData
        )
        
        print("ReminderService: Saved reminder: \(savedReminder.title ?? ""), ID: \(savedReminder.reminderID?.uuidString ?? "unknown"), List: \(savedReminder.list?.name ?? "No List"), IsCompleted: \(savedReminder.isCompleted)")
        
        await postSaveOperations(for: savedReminder)
        NotificationCenter.default.post(name: .reminderAdded, object: nil) // Notify observers
        
        return savedReminder
    }
    
    private func saveReminderToContext(
        reminder: Reminder?,
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
        let context = persistentContainer.viewContext
        
        return try await context.perform {
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
            
            self.setReminderPhotos(reminderToSave: reminderToSave, photos: photos, context: context)
            self.setReminderLocation(reminderToSave: reminderToSave, location: location, radius: radius, context: context)
            self.setReminderVoiceNote(reminderToSave: reminderToSave, voiceNoteData: voiceNoteData, context: context)
            
            try context.save()
            
            if reminderToSave.objectID.isTemporaryID {
                try context.obtainPermanentIDs(for: [reminderToSave])
            }
            
            print("ReminderService: Saved reminder: \(reminderToSave.title ?? ""), ID: \(reminderToSave.objectID), List: \(reminderToSave.list?.name ?? "No List"), IsCompleted: \(reminderToSave.isCompleted)")
            
            return reminderToSave
        }
    }
    
    private func postSaveOperations(for savedReminder: Reminder) async {
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        
        locationService.startMonitoringLocation(for: savedReminder)
        
        do {
            let updatedReminders = try await fetchReminders()
            await MainActor.run {
                self.setReminders(updatedReminders)
            }
            print("Fetched and updated reminders after saving. Count: \(updatedReminders.count)")
        } catch {
            logger.error("Failed to fetch reminders after saving: \(error.localizedDescription)")
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
        
        print("ReminderService: setReminderProperties, set start: \(reminderToSave.startDate ?? Date()), end: \(reminderToSave.endDate ?? Date())")
    }
    
    public func fetchFocusFilters() async throws -> [FocusFilterEntity] {
        logger.info("Starting to fetch focus filters")
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<FocusFilter> = FocusFilter.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusFilter.focusFilterName, ascending: true)]
            
            do {
                let fetchedFilters = try self.persistentContainer.viewContext.fetch(request)
                self.logger.info("Fetched \(fetchedFilters.count) focus filters")
                return fetchedFilters.map { filter in
                    FocusFilterEntity(id: filter.focusFilterID ?? UUID(), name: filter.focusFilterName ?? "Unnamed Filter")
                }
            } catch {
                self.logger.error("Failed to fetch focus filters: \(error.localizedDescription)")
                throw error
            }
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
    
    private func setReminderPhotos(reminderToSave: Reminder, photos: [UIImage], context: NSManagedObjectContext) {
        if let existingPhotos = reminderToSave.photos {
            for case let photo as ReminderPhoto in existingPhotos {
                context.delete(photo)
            }
            reminderToSave.photos = nil
        }
        
        let reminderPhotos = photos.map { createReminderPhoto(from: $0, in: context) }
        reminderToSave.photos = NSSet(array: reminderPhotos)
    }
    
    private func setReminderLocation(
        reminderToSave: Reminder,
        location: CLLocationCoordinate2D?,
        radius: Double?,
        context: NSManagedObjectContext
    ) {
        if let location = location, let radius = radius {
            let locationEntity = Location(context: context)
            locationEntity.latitude = location.latitude
            locationEntity.longitude = location.longitude
            locationEntity.name = "Reminder Location"
            reminderToSave.location = locationEntity
            reminderToSave.radius = radius
        } else {
            reminderToSave.location = nil
            reminderToSave.radius = 0
        }
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
                self.logger.info("Fetched \(fetchedReminders.count) reminders")
                fetchedReminders.forEach { reminder in
                    print("Fetched reminder: \(reminder.title ?? "Untitled"), Start: \(reminder.startDate ?? Date()), End: \(reminder.endDate ?? Date()), List: \(reminder.list?.name ?? "No List"), IsCompleted: \(reminder.isCompleted)")
                }
                return fetchedReminders
            } catch {
                self.logger.error("Failed to fetch reminders: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    public func fetchUnassignedAndIncompleteReminders() async throws -> [Reminder] {
        print("Fetching unassigned and incomplete reminders")
        let reminders = try await fetchReminders(
            withPredicate: "list == nil AND isCompleted == false",
            sortKey: "startDate",
            ascending: true
        )
        print("Fetched \(reminders.count) unassigned and incomplete reminders")
        return reminders
    }
    
    public func fetchSubHeadings(for taskList: TaskList) async throws -> [SubHeading] {
        return try await subheadingService.fetchSubHeadings(for: taskList)
    }
    
    public func getReminder(withID objectID: NSManagedObjectID) throws -> Reminder {
        let context = persistentContainer.viewContext
        guard let reminder = try context.existingObject(with: objectID) as? Reminder else {
            throw NSError(domain: "com.hexagon", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reminder not found"])
        }
        return reminder
    }
    
    public func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async throws {
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
        let context = persistentContainer.viewContext
        try await context.perform {
            context.delete(reminder)
            try context.save()
        }
        
        NotificationCenter.default.post(name: .reminderAdded, object: nil)
        let updatedReminders = try await fetchReminders()
        setReminders(updatedReminders)
    }
    
    private func fetchReminder(withTitle title: String) async -> Reminder? {
        let reminders = try? await fetchReminders(
            withPredicate: "title == %@",
            predicateArguments: [title]
        )
        return reminders?.first
    }
    
    private func createReminderPhoto(from image: UIImage, in context: NSManagedObjectContext) -> ReminderPhoto {
        let photo = ReminderPhoto(context: context)
        photo.photoData = image.jpegData(compressionQuality: 0.8)
        return photo
    }
    
    public func updateTaskLists() async throws -> [TaskList] {
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<TaskList> = TaskList.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskList.order, ascending: true)]
            do {
                let fetchedTaskLists = try self.persistentContainer.viewContext.fetch(request)
                self.taskLists = fetchedTaskLists
                return fetchedTaskLists
            } catch {
                throw error
            }
        }
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
    
    public func fetchTags() async throws -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        return try await persistentContainer.viewContext.perform {
            try self.persistentContainer.viewContext.fetch(request)
        }
    }
    
    public func createTag(name: String) async throws -> Tag {
        let context = persistentContainer.viewContext
        return try await context.perform {
            let newTag = Tag(context: context)
            newTag.name = name
            newTag.tagID = UUID()
            try context.save()
            return newTag
        }
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
            logger.error("Failed to get reminders count for list: \(error.localizedDescription)")
            return 0
        }
    }
    
    public func saveTaskToCalendar(title: String, startDate: Date, duration: TimeInterval) async throws {
        let eventStore = EKEventStore()
        
        let authorizationStatus = try await eventStore.requestFullAccessToEvents()
        guard authorizationStatus else {
            throw NSError(domain: "com.yourdomain.Hexagon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar access denied"])
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(duration * 60)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
    }
    
    public func fetchLocations() async throws -> [Location] {
        logger.info("Starting to fetch locations")
        return try await persistentContainer.viewContext.perform {
            let request: NSFetchRequest<Location> = Location.fetchRequest()
            request.predicate = nil
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.name, ascending: true)]
            
            do {
                let fetchedLocations = try self.persistentContainer.viewContext.fetch(request)
                self.logger.info("Fetched \(fetchedLocations.count) locations")
                return fetchedLocations
            } catch {
                self.logger.error("Failed to fetch locations: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    public func saveLocation(name: String, latitude: Double, longitude: Double) async throws -> Location {
        let context = persistentContainer.viewContext
        
        return try await context.perform {
            let newLocation = Location(context: context)
            newLocation.name = name
            newLocation.latitude = latitude
            newLocation.longitude = longitude
            
            try context.save()
            return newLocation
        }
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

extension Notification.Name {
    public static let reminderAdded = Notification.Name("reminderAdded")
}
