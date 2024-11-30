//
//  ReminderModificationService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 16/09/2024.
//

import Foundation
import CoreData
import os
import UIKit
import Combine

public protocol ReminderModifying {
    func saveReminder(
        reminder: Reminder?,
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
        voiceNoteData: Data?,
        repeatOption: String?,
        customRepeatInterval: Int16
    ) async -> Result<Reminder, Error>
    
    func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async -> Result<Void, Error>
    func deleteReminder(_ reminder: Reminder) async -> Result<Void, Error>
}

public protocol ReminderCreating {
    func saveReminder(
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
        voiceNoteData: Data?,
        repeatOption: String?,
        customRepeatInterval: Int16
    ) async throws -> Reminder
}

@MainActor
public class ReminderModificationService: ObservableObject, ReminderModifying, ReminderCreating {
    public static let shared = ReminderModificationService(persistenceController: PersistenceController.shared)
    private let persistentContainer: NSPersistentContainer
    private let logger = Logger(subsystem: "com.hexagon", category: "ReminderModificationService")
    
    public init(persistenceController: PersistenceController) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    public func saveReminder(
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
        voiceNoteData: Data?,
        repeatOption: String?,
        customRepeatInterval: Int16
    ) async throws -> Reminder {
        let result = await self.saveReminder(
            reminder: nil,
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
            voiceNoteData: voiceNoteData,
            repeatOption: repeatOption,
            customRepeatInterval: customRepeatInterval
        )
        
        switch result {
        case .success(let reminder):
            return reminder
        case .failure(let error):
            throw error
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
        voiceNoteData: Data?,
        repeatOption: String?,
        customRepeatInterval: Int16
    ) async -> Result<Reminder, Error> {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let context = persistentContainer.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                context.performAndWait {
                    do {
                        let reminderToSave: Reminder
                        if let reminder = reminder {
                            reminderToSave = context.object(with: reminder.objectID) as! Reminder
                        } else {
                            reminderToSave = Reminder(context: context)
                            reminderToSave.reminderID = UUID()
                        }
                        
                        reminderToSave.title = title
                        reminderToSave.startDate = startDate
                        reminderToSave.endDate = endDate
                        reminderToSave.notes = notes
                        reminderToSave.url = url
                        reminderToSave.priority = priority
                        reminderToSave.notifications = notifications.joined(separator: ",")
                        reminderToSave.isCompleted = false
                        reminderToSave.repeatOption = repeatOption
                        reminderToSave.customRepeatInterval = customRepeatInterval
                        
                        if let list = list {
                            let listInContext = context.object(with: list.objectID) as! TaskList
                            reminderToSave.list = listInContext
                            
                            if let listName = listInContext.name, listName == "Inbox" {
                                reminderToSave.isInInbox = true
                            } else {
                                reminderToSave.isInInbox = false
                            }
                        } else {
                            reminderToSave.isInInbox = true
                        }
                        
                        if let subHeading = subHeading {
                            let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
                            reminderToSave.subHeading = subHeadingInContext
                        }
                        
                        let tagsInContext = tags.map { tag in
                            return context.object(with: tag.objectID) as! ReminderTag
                        }
                        reminderToSave.tags = NSSet(array: tagsInContext)
                        
                        if let existingPhotos = reminderToSave.photos as? Set<ReminderPhoto> {
                            for photo in existingPhotos {
                                context.delete(photo)
                            }
                        }
                        
                        let reminderPhotos = photos.enumerated().map { index, image -> ReminderPhoto in
                            let reminderPhoto = ReminderPhoto(context: context)
                            reminderPhoto.order = Int16(index)
                            reminderPhoto.reminder = reminderToSave
                            reminderPhoto.photoData = image.jpegData(compressionQuality: 0.8)
                            return reminderPhoto
                        }
                        reminderToSave.photos = NSSet(array: reminderPhotos)
                        
                        if let voiceNoteData = voiceNoteData {
                            let voiceNote = reminderToSave.voiceNote ?? VoiceNote(context: context)
                            voiceNote.audioData = voiceNoteData
                            reminderToSave.voiceNote = voiceNote
                        } else if let voiceNote = reminderToSave.voiceNote {
                            context.delete(voiceNote)
                        }
                        
                        try context.save()
                        
                        let isNewReminder = reminder == nil
                        Task { @MainActor in
                            NotificationCenter.default.post(name: isNewReminder ? .reminderCreated : .reminderUpdated, object: nil)
                        }
                        
                        continuation.resume(returning: .success(reminderToSave))
                        
                    } catch {
                        self.logger.error("Failed to save reminder: \(error.localizedDescription)")
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func uncompleteTask(_ reminder: Reminder) async throws {
        let result = await updateReminderCompletionStatus(reminder: reminder, isCompleted: false)
        
        switch result {
        case .success:
            logger.info("Successfully marked task as incomplete: \(reminder.objectID)")
        case .failure(let error):
            logger.error("Failed to mark task as incomplete: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func updateReminderCompletionStatus(reminder: Reminder, isCompleted: Bool) async -> Result<Void, Error> {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let context = persistentContainer.newBackgroundContext()
                context.performAndWait {
                    do {
                        let reminderInContext = context.object(with: reminder.objectID) as! Reminder
                        reminderInContext.isCompleted = isCompleted
                        reminderInContext.completedAt = isCompleted ? Date() : nil
                        
                        if isCompleted {
                            reminderInContext.notifications = nil
                        }
                        
                        try context.save()
                        
                        Task { @MainActor in
                            NotificationCenter.default.post(name: .reminderUpdated, object: nil)
                        }
                        
                        continuation.resume(returning: .success(()))
                        
                    } catch {
                        self.logger.error("Failed to update reminder completion status: \(error.localizedDescription)")
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
    
    public func deleteReminder(_ reminder: Reminder) async -> Result<Void, Error> {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let context = persistentContainer.newBackgroundContext()
                context.performAndWait {
                    do {
                        let reminderInContext = context.object(with: reminder.objectID) as! Reminder
                        
                        if let photos = reminderInContext.photos as? Set<ReminderPhoto> {
                            for photo in photos {
                                context.delete(photo)
                            }
                        }
                        if let voiceNote = reminderInContext.voiceNote {
                            context.delete(voiceNote)
                        }
                        
                        reminderInContext.tags = nil
                        reminderInContext.subHeading = nil
                        
                        context.delete(reminderInContext)
                        try context.save()
                        
                        Task { @MainActor in
                            NotificationCenter.default.post(name: .reminderUpdated, object: nil)
                        }
                        
                        continuation.resume(returning: .success(()))
                        
                    } catch {
                        self.logger.error("Failed to delete reminder: \(error.localizedDescription)")
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        } catch {
            return .failure(error)
        }
    }
}

extension ReminderModificationService: ReminderOperations {
    public func moveReminders(from source: IndexSet, to destination: Int, in subHeading: SubHeading) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = persistentContainer.newBackgroundContext()
            context.performAndWait {
                do {
                    let subHeadingInContext = context.object(with: subHeading.objectID) as! SubHeading
                    var reminders = Array(subHeadingInContext.reminders ?? NSSet()) as! [Reminder]
                    reminders.move(fromOffsets: source, toOffset: destination)
                    
                    for (index, reminder) in reminders.enumerated() {
                        reminder.order = Int16(index)
                    }
                    
                    try context.save()
                    
                    Task { @MainActor in
                        NotificationCenter.default.post(name: .reminderUpdated, object: nil)
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

public extension Notification.Name {
    static let reminderUpdated = Notification.Name("reminderUpdated")
    static let reminderCreated = Notification.Name("reminderCreated")
}
