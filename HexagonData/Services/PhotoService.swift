//
//  PhotoService.swift
//  Hexagon
//
//  Created by Kieran Lynch on 03/10/2024.
//

import Foundation
import CoreData
import UIKit

@MainActor
public class PhotoService {
    public static let shared = PhotoService()
    
    private let persistentContainer: NSPersistentContainer
    
    public init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistentContainer = persistenceController.persistentContainer
    }
    
    public func setReminderPhotos(reminderToSave: Reminder, photos: [UIImage], context: NSManagedObjectContext) async throws {
        if let existingPhotos = reminderToSave.photos {
            for case let photo as ReminderPhoto in existingPhotos {
                context.delete(photo)
            }
            reminderToSave.photos = nil
        }
        
        let reminderPhotos = photos.map { createReminderPhoto(from: $0, in: context) }
        reminderToSave.photos = NSSet(array: reminderPhotos)
    }
    
    private func createReminderPhoto(from image: UIImage, in context: NSManagedObjectContext) -> ReminderPhoto {
        let photo = ReminderPhoto(context: context)
        photo.photoData = image.jpegData(compressionQuality: 0.8)
        return photo
    }
}
