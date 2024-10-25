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
        await context.perform {
            if let existingPhotos = reminderToSave.photos {
                for case let photo as ReminderPhoto in existingPhotos {
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
        
        try context.save();
    }
    
    public func getPhotos(for reminder: Reminder) -> [UIImage] {
        guard let photos = reminder.photos as? Set<ReminderPhoto> else {
            return []
        }
        
        return photos.compactMap { photo in
            guard let photoData = photo.photoData else { return nil }
            return UIImage(data: photoData)
        }
    }
}
